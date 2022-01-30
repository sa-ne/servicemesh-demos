#!/bin/bash

# Script will try to get list of managed clusters, generate a smcp for each of them and output an argocd application for each of them
# Script is required to be run on Hub ACM Cluster cli
# Script assumes the local cluster is the default argocd cluster
# Script will try to login to argocd 
# Script assumes argocd htpasswd auth for argocd is still available. Overwrite values if not
# Script requires oc user cluster-admin privilege to get details, user should already be logged in before running script

#Cluster Variables
  CLUSTER_ARGO_LABEL="${1:-demo-usage=smesh-demo-clusters}"  
  BASEDIR="${2:-$(dirname "$0")}"
  OUTPUT_DIR="${3:-tmp}"
  MANIFESTDIR=$(dirname "$BASEDIR")
  ARGOCD_URL="${4:-$(oc get routes/openshift-gitops-server -n openshift-gitops -o 'jsonpath={.status.ingress[0].host}')}"
  ARGOCD_USERNAME="${5:-admin}"
  ARGOCD_PASSWORD=$(oc get secrets/openshift-gitops-cluster -n openshift-gitops -o jsonpath='{.data.admin\.password}' | base64 -d)
  CLUSTER_INGRESS_LIST=()
  TIMEOUT=90
  PEER

#Function List
function startup_info(){
  echo """
  generate-smcp.sh script helps generate manifests for service mesh federation for a demo.
  Demo Link - https://github.com/sa-ne/servicemesh-demos/tree/main/use-cases/smesh-federation
  Script requires the oc client, argocd cli. See above link to get more information
  Run script with help flag to get more informarion about running script i.e ./generate-smcp.sh help
  Script requires oc user cluster-admin privilege to get details, user should already be logged in before running script
  """
}

function display_help(){ 
    echo """
    # Will Display Help,and values obtained that script will use to run and Exit
    # Usage Patterns
    Script will try to obtain the following variables if they are not provided,input variable based on number to update variable

    Usage: ./generate-smcp.sh ARGUMENTS

    ARGUMENTS:
    Description: Label applied to managed clusters to filter those in our demo gitops cluster, see https://github.com/sa-ne/servicemesh-demos/tree/main/use-cases/smesh-federation
    Value we will Use:
    CLUSTER_ARGO_LABEL="${1:-'demo-usage=smesh-demo-clusters'}"  

    Description: Folder used by repo to generate deployable and temporary manifests
    Value we will Use:
    BASEDIR="${2:-$(dirname "$0")}"

    Description:Local Sub Folder to be used to store temporary generated local manifests
    OUTPUT_DIR="tmp"
    
    Description:ArgoCD Hub URL, Script will attempt to log into url to create gitops application.
    Value we will Use:
    ARGOCD_URL="${4:-$(oc get routes/cluster -n openshift-gitops -o jsonpath="{.status.ingress[0].host}"))}"

    Description:ArgoCD Username to log into Hub Url, Script will attempt to log into url to create gitops application.
    Value we will Use:
    ARGOCD_USERNAME="${5:-admin}"

    Description:ArgoCD Passwordto log into Hub Url, Script will attempt to log into url to create gitops application.
    Value we will Use:
    ARGOCD_PASSWORD="oc get secrets/openshift-gitops-cluster -n openshift-gitops -o jsonpath='{.data.admin\.password}' | base64 -d"
    """
  exit 0;
}

function output_dir_exists (){
    if [ -d $BASEDIR/$1 ]
    then
      echo -e "\nDirectory already exists will not create"
    else
      mkdir $BASEDIR/$1
    fi   
}

function create_kubeconfig (){
    MANAGED_CLUSTER_NAME=$1
    echo -e "\nExtracting KUBECONFIG for $MANAGED_CLUSTER_NAME..."
    CLUSTER_KUBECONFIG=$(oc get secrets -n $MANAGED_CLUSTER_NAME -l hive.openshift.io/secret-type=kubeconfig -o jsonpath="{.items[0].data.kubeconfig}")

    TMP_KUBECONFIG=$BASEDIR/$OUTPUT_DIR/$MANAGED_CLUSTER_NAME-kubeconfig
    echo $CLUSTER_KUBECONFIG | base64 --decode > $TMP_KUBECONFIG
}


function argocd_loggedin (){
    if [ ${ARGOCD_URL} = "" ] || [ ${ARGOCD_USERNAME} = "" ] || [ ${ARGOCD_PASSWORD} = "" ]
    then
      exit_message "Can't login to ArgoCD, either url,username or password is empty"
    else
      argocd cluster list || argocd login $ARGOCD_URL --username $ARGOCD_USERNAME --password $ARGOCD_PASSWORD --insecure
    fi 
}

function argocd_health_status(){
  #$1 is application name
  app_name=$1
 
  echo -e "\nWaiting for $app_name until $TIMEOUT"
  argocd app wait $1 --timeout $TIMEOUT
  # sleepcount=0
  # syncstatus=$(argocd app get $app_name -o json | jq -r '.status.sync.status')
  # healthstatus=$(argocd app get $app_name -o json | jq -r '.status.health.status')

  # until [ "${syncstatus}"  = "Synced" ] && [ "${healthstatus}"  = "Healthy" ]
  # do
  #   if [ "${sleepcount}" -ge "${TIMEOUT}" ]
  #   then
  #     echo "Application $app_name did not become healthy in time"
  #     exit 1;      
  #   fi
  #   echo "Waiting for Application $app_name to sync and become healthy"
  #   sleep 3
  #   syncstatus=$(argocd app get $app_name -o json | jq -r '.status.sync.status')
  #   healthstatus=$(argocd app get $app_name -o json | jq -r '.status.health.status')
  #   sleepcount=$((sleepcount+3))
  # done
  
}
function argocd_local_app_sync(){
  #$1 is application name
  #$2 is local root directory
  #$3 is local path
  #$4 is resources to sync

  app_name=$1
  local_root_path=$2
  local_path=$3
  resources=$4

  echo -e "\n--------------------------------Syncing $app_name until $TIMEOUT----------------------------------------------------"
  argocd_loggedin
  if [ "${4}" != ""]
  then
    argocd app sync $app_name --local-repo-root $local_root_path --local $local_path --timeout $TIMEOUT --resources "${4}" || echo "Could not sync application $app_name"
  else
    argocd app sync $app_name --local-repo-root $local_root_path --local $local_path --timeout $TIMEOUT  || echo "Could not sync application $app_name"
  fi
  argocd_health_status $app_name || echo "Waiting for argo app $app_name to sync was unsuccessful"
  echo -e "\n---------------------------------Syncing $app_name until $TIMEOUT complete---------------------------------------------------"
}

function exit_message (){
  echo $1
  exit 0;
}

# Display help
if [ "${CLUSTER_ARGO_LABEL}" = "help" ]
then
   display_help
fi

#Create directory to store output templates 
output_dir_exists $OUTPUT_DIR

#Clean Temporary Directory
rm -rf $BASEDIR/$OUTPUT_DIR/*

#Clean Infra Manifest Directory since they will be regenerated
rm -rf $MANIFESTDIR/infra/deployables-federation/base/*

# Get list of managed clusters we will use to generate service mesh manifests
readarray -t CLUSTER_LIST_NAME < <(oc get managedclusters -l $CLUSTER_ARGO_LABEL --no-headers | awk '{print $1}')
readarray -t CLUSTER_LIST_API < <(oc get managedclusters -l $CLUSTER_ARGO_LABEL --no-headers | awk '{print $3}')

#Exit if not enough clusters
if [ ${CLUSTER_LIST_NAME[@]} -lt 1 ]
then
  exit_message "Did not get any other clusters(apart from maybe the local cluster), exiting"
fi

#Append local-cluster
CLUSTER_LIST_NAME[${#CLUSTER_LIST_NAME[@]}]="local-cluster"
CLUSTER_LIST_API[${#CLUSTER_LIST_API[@]}]="https://kubernetes.default.svc"

# Get ManagedClusters tagged with the CLUSTER_ARGO_LABEL
for cluster_name in "${CLUSTER_LIST_NAME[@]}"
do
  sed "s/<cluster_name>/$cluster_name/g" $BASEDIR/add-egress-template.yaml-tmp | sed "s/<cluster_name>/$cluster_name/g" > $BASEDIR/$OUTPUT_DIR/egress-$cluster_name.yaml
  sed "s/<cluster_name>/$cluster_name/g" $BASEDIR/add-ingress-template.yaml-tmp | sed "s/<cluster_name>/$cluster_name/g" > $BASEDIR/$OUTPUT_DIR/ingress-$cluster_name.yaml
done

# Generate SMCP,ServiceMesh Peer and Argo Applications for each Cluster
arraycount=0
for cluster_name in "${CLUSTER_LIST_NAME[@]}"
do
  #Copy Templates we will be using
  cp $BASEDIR/smcp-template.yaml $BASEDIR/$OUTPUT_DIR/smcp-$cluster_name-template.yaml
  cp $BASEDIR/application-template.yaml $BASEDIR/$OUTPUT_DIR/application-$cluster_name-template.yaml
    
    
  #Create Egress/Ingress Cluster Lists exempting this cluster
  find $BASEDIR/$OUTPUT_DIR -name "egress-*.yaml" | grep -v $cluster_name | xargs -t cat > $BASEDIR/$OUTPUT_DIR/tmp_sed_egress
  find $BASEDIR/$OUTPUT_DIR -name "ingress-*.yaml" | grep -v $cluster_name | xargs -t cat > $BASEDIR/$OUTPUT_DIR/tmp_sed_ingress
    
  #Edit the SMCP Template for this cluster
  sed -i "/additionalEgress: {}/ r $BASEDIR/$OUTPUT_DIR/tmp_sed_egress" $BASEDIR/$OUTPUT_DIR/smcp-$cluster_name-template.yaml 
  sed -i "/additionalIngress: {}/ r $BASEDIR/$OUTPUT_DIR/tmp_sed_ingress" $BASEDIR/$OUTPUT_DIR/smcp-$cluster_name-template.yaml
  sed -i "s/additionalEgress: {}/additionalEgress:/g" $BASEDIR/$OUTPUT_DIR/smcp-$cluster_name-template.yaml 
  sed -i "s/additionalIngress: {}/additionalIngress:/g" $BASEDIR/$OUTPUT_DIR/smcp-$cluster_name-template.yaml
  sed -i "s/additionalIngress: {}/additionalIngress:/g" $BASEDIR/$OUTPUT_DIR/smcp-$cluster_name-template.yaml
  sed -i "s/<cluster_name>/$cluster_name/g" $BASEDIR/$OUTPUT_DIR/smcp-$cluster_name-template.yaml

  #Edit the Application Template for this cluster
  sed -i "s|<cluster_api>|${CLUSTER_LIST_API[$arraycount]}|g" $BASEDIR/$OUTPUT_DIR/application-$cluster_name-template.yaml
  sed -i "s/<cluster_name>/$cluster_name/g" $BASEDIR/$OUTPUT_DIR/application-$cluster_name-template.yaml

  #Copy SMCP template to overlay Directory
  mkdir $MANIFESTDIR/infra/deployables-federation/base/$cluster_name
  mv $BASEDIR/$OUTPUT_DIR/smcp-$cluster_name-template.yaml $MANIFESTDIR/infra/deployables-federation/base/$cluster_name/smcp-$cluster_name.yaml

  #Copy Application template to Base Directory
  mv $BASEDIR/$OUTPUT_DIR/application-$cluster_name-template.yaml $MANIFESTDIR/infra/application-$cluster_name.yaml

  #Create the ArgoCD Application for this Cluster and use ArgoCD to sync local 
  oc create -f $MANIFESTDIR/infra/application-$cluster_name.yaml -n openshift-gitops

  #Wait until Application exists
  echo -e "\n--------------------------Waiting for Application federation-mesh-generate-$cluster_name to exist------------------------------- "
  sleepcount=0
  until oc get application/federation-mesh-generate-$cluster_name -n openshift-gitops
  do
    if [ "${sleepcount}" -ge "${TIMEOUT}" ]
    then
      break
    fi
    echo -e "\nWaiting for Application to exist"
    sleep 3
    sleepcount=$((sleepcount+3))
  done #until oc get application/federation-mesh-generate-$cluster_name -n openshift-gitops
  echo -e "\n--------------------------Waiting for Application federation-mesh-generate-$cluster_name complete ------------------------------- "

  #Use Argo to Sync Application locally, This should create the SMCP on all Clusters as required
  argocd_local_app_sync federation-mesh-generate-$cluster_name $MANIFESTDIR $MANIFESTDIR/infra/deployables-federation/base/$cluster_name
  arraycount=$((arraycount+1))
done #for cluster_name in "${CLUSTER_LIST_NAME[@]}"

# At this stage if eveything has installed well we should have the smcp object available in all clusters
# We will try get details of cluster information for each cluster necessary to complete the federation
arraycount=0
for cluster_name in "${CLUSTER_LIST_NAME[@]}"
do
  #Create ManagedCluster Kubeconfig
  if [ $cluster_name != "local-cluster" ]
  then
    create_kubeconfig $cluster_name
    ockube="--kubeconfig $BASEDIR/$OUTPUT_DIR/$cluster_name-kubeconfig"
  else
    ockube=""
  fi

  #Loop through 2nd time to create tiered objects,n^2 ..sad face
  let arraylength=${#CLUSTER_LIST_NAME[@]}-1
  echo -e "\n$arraylength"
  #for count in {0..$arraylength}
  for (( count=0; count<=$arraylength; count++ ))
  do
    if [ "${count}" -eq "${arraycount}" ]
    then
      continue
    fi
    peerclustername="${CLUSTER_LIST_NAME[$count]}"

    #Wait until SMCP Objects Exist
    echo -e"\n--------------------------Waiting for SMCP Object for $cluster_name to exist------------------------------- "
    sleepcount=0
    until [ $(oc $ockube get smcp -n federation-demo -o json | jq '.items[0].status.readiness'.pending) = "null" ]
    do
      if [ "${sleepcount}" -ge "${TIMEOUT}" ]
      then
        echo -e "\nService Mesh did not become ready in time"
        break
      fi
    
    echo -e"\nWaiting for SMCP to exist"    
    sleep 3
    sleepcount=$((sleepcount+3))    
    done
    echo -e "\n--------------------------Waiting for SMCP Object for $cluster_name Complete------------------------------- "
    
    #Copy and Edit Cluster Configmap for Peer Cluster
    oc $ockube get configmap/istio-ca-root-cert -n federation-demo -o yaml > $MANIFESTDIR/infra/deployables-federation/base/$peerclustername/$cluster_name-istio-ca-root-cert.yaml
    sed -i "s/istio-ca-root-cert/$cluster_name-istio-ca-root-cert/g" $MANIFESTDIR/infra/deployables-federation/base/$peerclustername/$cluster_name-istio-ca-root-cert.yaml
    sed -E -i 's/^  resourceVersion:.*//g' $MANIFESTDIR/infra/deployables-federation/base/$peerclustername/$cluster_name-istio-ca-root-cert.yaml
    sed -E -i 's/^  uid:.*//g' $MANIFESTDIR/infra/deployables-federation/base/$peerclustername/$cluster_name-istio-ca-root-cert.yaml

    #Create servicemeshpeer for Peer Cluster
    cp $BASEDIR/servicemeshpeer-template.yaml $MANIFESTDIR/infra/deployables-federation/base/$peerclustername/servicemeshpeer-$cluster_name.yaml
    sed -i "s/<cluster_name>/$cluster_name/g" $MANIFESTDIR/infra/deployables-federation/base/$peerclustername/servicemeshpeer-$cluster_name.yaml
    sed -i "s/<peer_name>/$peerclustername/g" $MANIFESTDIR/infra/deployables-federation/base/$peerclustername/servicemeshpeer-$cluster_name.yaml

    #Get. and replace cluster ingress
    echo "--------------------------Waiting until Cluster ingress $cluster_ingress is ready and has a hostname------------------------------- "
    cluster_ingress=""
    
    until [ "${cluster_ingress}" != "" ]
    do
      if [ "${sleepcount}" -ge "${TIMEOUT}" ]
      then
        echo "Cluster Ingress $cluster_ingress did not become avaialble in $TIMEOUT sec"
        break
      fi
    
    echo "Waiting for Cluster Ingress $cluster_ingress to become available"    
    sleep 3
    cluster_ingress=$(oc $ockube get service/ingress-$peerclustername -n federation-demo -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    sleepcount=$((sleepcount+3))
    done
    echo -e "\n--------------------------Waiting until Cluster ingress $cluster_ingress is complete------------------------------- "
    sed -i "s/<ingress_addr>/$cluster_ingress/g" $MANIFESTDIR/infra/deployables-federation/base/$peerclustername/servicemeshpeer-$cluster_name.yaml
  done

#ArgoCD Update Application with new manifests

arraycount=$((arraycount+1))
done

echo "Sync all created manifests"
for cluster_name in "${CLUSTER_LIST_NAME[@]}"
do
  argocd_local_app_sync federation-mesh-generate-$cluster_name $MANIFESTDIR $MANIFESTDIR/infra/deployables-federation/base/$cluster_name 'v1:ConfigMap'
done



#Clean Temporary Directory
rm -rf $BASEDIR/$OUTPUT_DIR