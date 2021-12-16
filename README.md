# servicemesh-demos

## ServiceMesh Demos

### TODO - Summary of what this repo contains

### Pre-Requisites

- oc client >= 4.8
- [Openshift Policy Generator Kustomize Plugin](https://github.com/open-cluster-management/policy-generator-plugin#as-a-kustomize-plugin)

---

### - Install ACM Operator and create ACM Hub

- Operator via [Gitops](https://github.com/redhat-cop/gitops-catalog/tree/main/advanced-cluster-management/operator)
- Hub via [Gitops](https://github.com/redhat-cop/gitops-catalog/tree/main/advanced-cluster-management/instance)
- Sample Script(Might not be updated) - ./acm/install.sh

### Install Openshift-gitops Operator on all Openshift Clusters

- kustomize build ./openshift-gitops/ --enable-alpha-plugins | oc apply -f -

### Install Openshift ElasticSearch Operator on all Openshift Clusters

- kustomize build ./elasticsearch --enable-alpha-plugins | oc apply -f -

### Install Openshift Kiali Operator on all Openshift Clusters

- kustomize build ./kiali --enable-alpha-plugins | oc apply -f -

### Install Openshift Jaeger Operator on all Openshift Clusters

- kustomize build ./jaeger --enable-alpha-plugins | oc apply -f -
  
### Install Openshift Virtualization Operator on all Openshift Clusters

- kustomize build ./openshift-virtualization --enable-alpha-plugins | oc apply -f -

### Install Openshift Service Mesh Operator on all Openshift Clusters

- kustomize build ./servicemesh/ --enable-alpha-plugins | oc apply -f -



oc label namespace openshift-cnv argocd.argoproj.io/managed-by=openshift-gitops
oc label namespace istio-system argocd.argoproj.io/managed-by=openshift-gitops