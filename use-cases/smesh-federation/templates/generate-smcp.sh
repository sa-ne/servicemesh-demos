#!/bin/bash -x

# Script will try to get list of managed clusters, generate a smcp for each of them and output an argocd application for each of them
# Script is required to be run on Hub ACM Cluster cli
# Script assumes the local cluster is the default argocd cluster

#CLUSTER_ARGO_LABEL="vendor=OpenShift"
CLUSTER_ARGO_LABEL="demo-usage=smesh-demo-clusters"
OUTPUT_DIR="tmp"
BASEDIR=$(dirname $0)


readarray -t cluster_list_name < <(oc get managedclusters -l $CLUSTER_ARGO_LABEL --no-headers | awk '{print $1}')
readarray -t cluster_list_api < <(oc get managedclusters -l $CLUSTER_ARGO_LABEL --no-headers | awk '{print $2}')

function output_dir_exists () {
    if [ -d $BASEDIR/$1 ]
    then
      echo "Directory already exists will not create"
    else
      mkdir $BASEDIR/$1
    fi   
}



#Create directory to store output templates 
output_dir_exists $OUTPUT_DIR


# Get MangedClusters for local-cluster
sed "s/<cluster_name>/local-cluster/g" $BASEDIR/add-egress-template.yaml-tmp | sed "s/<cluster_name>/local-cluster/g" > $BASEDIR/$OUTPUT_DIR/egress-local-cluster.yaml
sed "s/<cluster_name>/local-cluster/g" $BASEDIR/add-ingress-template.yaml-tmp | sed "s/<mesh-network>/local-cluster/g" > $BASEDIR/$OUTPUT_DIR/ingress-local-cluster.yaml

# Get MangedClusters tagged with the ARGO LABEL
for cluster_name in $cluster_list_name
do
  sed "s/<cluster_name>/$cluster_name/g" $BASEDIR/add-egress-template.yaml-tmp | sed "s/<mesh-network>/$cluster_name/g" > $BASEDIR/$OUTPUT_DIR/egress-$cluster_name.yaml
  sed "s/<cluster_name>/$cluster_name/g" $BASEDIR/add-ingress-template.yaml-tmp | sed "s/<mesh-network>/$cluster_name/g" > $BASEDIR/$OUTPUT_DIR/ingress-$cluster_name.yaml
done

# Generate SMCP for each Cluster
for cluster_name  in $cluster_list_name
do  
  find $BASEDIR/$OUTPUT_DIR -name "egress-*.yaml" | grep -v $cluster_name | xargs -t cat > $BASEDIR/$OUTPUT_DIR/tmp_sed_egress
  find $BASEDIR/$OUTPUT_DIR -name "ingress-*.yaml" | grep -v $cluster_name | xargs -t cat > $BASEDIR/$OUTPUT_DIR/tmp_sed_ingress
  cp $BASEDIR/smcp-template.yaml $BASEDIR/$OUTPUT_DIR/smcp-$cluster_name-template.yaml
  sed -i "/additionalEgress: {}/ r $BASEDIR/$OUTPUT_DIR/tmp_sed_egress" $BASEDIR/$OUTPUT_DIR/smcp-$cluster_name-template.yaml 
  sed -i "/additionalIngress: {}/ r $BASEDIR/$OUTPUT_DIR/tmp_sed_ingress" $BASEDIR/$OUTPUT_DIR/smcp-$cluster_name-template.yaml
  sed -i "s/additionalEgress: {}/additionalEgress:/g" $BASEDIR/$OUTPUT_DIR/smcp-$cluster_name-template.yaml 
  sed -i "s/additionalIngress: {}/additionalIngress:/g" $BASEDIR/$OUTPUT_DIR/smcp-$cluster_name-template.yaml
done

# #sed -e "s/localhost/$(sed 's:/:\\/:g' file2)/" file1
# egress-templates=$(ls $BASEDIR/$OUTPUT_DIR/egress-*.yaml)
# for template in $egress-templates
# do
#   echo $template