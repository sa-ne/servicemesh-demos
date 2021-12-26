#!/bin/bash

GITOPS_LINK="${GITOPS_LINK:=https://github.com/redhat-cop/gitops-catalog.git}"
PULL_SECRET_LOCATION="${PULL_SECRET_LOCATION:-}"
CLONE_FOLDER="${GITOPS_CLONE_FOLDER:=/tmp/gitops}"
CHANNEL="${ACM_CHANNEL:=release-2.4}"
ACM_NAMESPACE="${ACM_NAMESPACE:=open-cluster-management}"
PULL_SECRET_NAME="${PULL_SECRET_NAME:=multiclusterhub-operator-pull-secret}"
MULTICLUSTER_OBSERVABILIITY="true"

function clone () {
# Provide $1 link to clone
# Provide $2 Directory to clone to
    if [ -d $2 ]
    then
      echo "Directory already exists will not create"
    else
      git clone $1 $2 && echo "Cloned to $2" || exit 1
    fi   
}

function check_secret_exists() {
     oc get secret/$1 -n $2 
}

#Clone Gitops Repo
echo "Cloning Gitops Repo"
clone $GITOPS_LINK $CLONE_FOLDER

#Create ACM Operator
oc apply -k $CLONE_FOLDER/advanced-cluster-management/operator/overlays/$CHANNEL
until [ $(oc get csv -l operators.coreos.com/advanced-cluster-management.open-cluster-management='' -n open-cluster-management -o jsonpath='{.items[0].status.phase}') = "Succeeded" ];do \
echo "Creating ACM Operator" && sleep 5;done

#Create Pull Secret if not exists
check_secret_exists $PULL_SECRET_NAME $ACM_NAMESPACE
secret_status=$?
if [[ -n ${PULL_SECRET_LOCATION} ]] && [[ $secret_status -ne 0  ]]
then
  #Create Pull Secret for ACM
  oc create secret generic $PULL_SECRET_NAME -n $ACM_NAMESPACE \
  --from-file=.dockerconfigjson=$PULL_SECRET_LOCATION \
  --type=kubernetes.io/dockerconfigjson && \
  (echo "sleeping for secret creation" && sleep 10 ) || (echo "Could not create secret")
fi

check_secret_exists $PULL_SECRET_NAME $ACM_NAMESPACE
secret_status=$?
if [[ $secret_status -eq 0 ]]
then
  #Append Pull Secret to Overlay
  mkdir -p $CLONE_FOLDER/advanced-cluster-management/instance/overlays/secret
  touch $CLONE_FOLDER/advanced-cluster-management/instance/overlays/secret/kustomization.yaml
  echo """
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

bases:
 - ../../base 

patches:
  - target:
      kind: MultiClusterHub
      name: multiclusterhub
    patch: |-
      - op: add
        path: /spec
        value: {}
      - op: add
        path: /spec/imagePullSecret
        value: $PULL_SECRET_NAME """ > $CLONE_FOLDER/advanced-cluster-management/instance/overlays/secret/kustomization.yaml
    #Create ACM Hub with pullsecret
    oc apply -k $CLONE_FOLDER/advanced-cluster-management/instance/overlays/secret/
else
    #Create ACM Hub without pullsecret
    oc apply -k $CLONE_FOLDER/advanced-cluster-management/instance/base
fi



if [[ $MULTICLUSTER_OBSERVABILIITY = "true" ]]
then
    
    #Make Sure Multi-ClusterHub Exists First
    until [ $(oc get multiclusterhub -n open-cluster-management -o jsonpath='{.items[0].status.phase}') = "Running" ];do \
    echo "Creating MultiClusterHub" && sleep 5;done
    
    echo "Export your Variables for Object Storage, see thanos-object-storage.yaml for environment variables"

    #Create Observability Namespace
    oc create namespace open-cluster-management-observability

    #Try obtain pull secret
    DOCKER_CONFIG_JSON=`oc extract secret/multiclusterhub-operator-pull-secret -n open-cluster-management --to=-`
    secret_status=$?
    if [[ $secret_status -eq 0 ]] || [[ $DOCKER_CONFIG_JSON == "" ]]
    then
      DOCKER_CONFIG_JSON=`oc extract secret/pull-secret -n openshift-config --to=-`
      secret_status=$?
      if [[ $secret_status -eq 1 ]]
      then
        echo "Could not get pull secret to create"
        exit 1
      fi
      oc create secret generic multiclusterhub-operator-pull-secret \
      -n open-cluster-management-observability \
      --from-literal=.dockerconfigjson="$DOCKER_CONFIG_JSON" \
      --type=kubernetes.io/dockerconfigjson
    fi

    #Create object storage secret, make sure values are set via env variables, see thanos object storage
    echo "Create object storage secret, make sure values are set via env variables, see thanos object storage"
    envsubst < ./operators/acm/thanos-object-storage.yaml | oc create -f -

    #Create the multicluster observability object
    echo "Create the multicluster observability object"
    echo """
apiVersion: observability.open-cluster-management.io/v1beta2
kind: MultiClusterObservability
metadata:
  name: observability
spec:
  observabilityAddonSpec: {}
  storageConfig:
    metricObjectStorage:
      name: thanos-object-storage
      key: thanos.yaml
""" | oc create -f -



fi