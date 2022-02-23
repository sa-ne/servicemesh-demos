# ServiceMesh Federation

Status: Not Ready

This case tries to show service mesh federation example between 2 clusters.

## Pre-Requisites

- Please read [Federation](https://docs.openshift.com/container-platform/4.9/service_mesh/v2x/ossm-federation.html)
- Requires Openshift Gitops and Service Mesh Installed
- This example uses Red Hat Advanced Cluster Management to register remote Openshift Clusters for Argo to Control
- Clusters must be managed clusters in ACM
- Repo presently only supports clusters that support the LoadBalancer Service

## Deploy Federated Clusters

### Install Pre-Requisites

- [Install all required Operators and Traffic Generation Image](https://github.com/sa-ne/servicemesh-demos#servicemesh-demos)

- ArgoCD CLI should be installed on node running this script

## Steps

The default manifests used are in [same-repo](https://github.com/sa-ne/servicemesh-demos/tree/main/operators/acm/argo-deployables).The manifests uses the openshift local-cluster as the hub Argo cluster and will create a ManagedClusterSet and add managed clusters based on labels to a central ArgoCD(Default - Local Openshift Cluster).

1 Git clone this repo  
 `git clone https://github.com/sa-ne/servicemesh-demos#servicemesh-demos`

2 Change Directory into folder  
 `cd ./servicemesh-demos`

3 Deploy the ACM GitOps Cluster Object  
 `kustomize build ./operators/acm/acm-openshift-gitops/ --enable-alpha-plugins | oc create -f -`

4 Label Required ManagedClusters to add them to the ManagedClusterSet- Sample Below  
 `oc label managedcluster/<CLUSTER_NAME> cluster.open-cluster-management.io/clusterset=smesh-demo-clusters --overwrite=true`

OR

Label all ManagedClusters including the local cluster  
 `for mc in $(oc get managedclusters -A -o name | grep -v "local-cluster");do oc label $mc cluster.open-cluster-management.io/clusterset=smesh-demo-clusters --overwrite=true;done`

5 Label Required ManagedClusters to add them to the ArgoCD Hub - Sample Below. Note: except you are changing the default gitops don't label the local cluster here as its added to the default Openshift Gitops Cluster.  
 `oc label managedcluster/<CLUSTER_NAME> demo-usage=smesh-demo-clusters --overwrite=true`

OR

Label all ManagedClusters except the local cluster  
 `for mc in $(oc get managedclusters -A -o name | grep -v "local-cluster");do oc label $mc demo-usage=smesh-demo-clusters --overwrite=true;done`

6 Confirm clusters are pressent in Openshift Gitops either via the UI or CLI. See ./templates/generate-smcp.sh script for sample.

```bash
export ARGOCD_USERNAME=admin
export ARGOCD_PASSWORD=$(oc get secrets/openshift-gitops-cluster -n openshift-gitops -o jsonpath='{.data.admin\.password}'| base64 -d)
export ARGOCD_URL=$(oc get route/openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}')
argocd login $ARGOCD_URL --username $ARGOCD_USERNAME --password $ARGOCD_PASSWORD --insecure && argocd cluster list
```

7 Create the infra ApplicationSet to create necessary pre-required infrastructure on all clusters.  
 `oc create -f ./use-cases/smesh-federation/infra/infra-applicationset.yaml -n openshift-gitops`

8 ServiceMesh federation requires a lot of dynamic data between each cluster to be configured.
There's an all on one script to help create the necessary manifests.

```bash
./use-cases/smesh-federation/templates/generate-smcp.sh
```
