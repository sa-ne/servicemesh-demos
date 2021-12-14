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

### - Create and Import Openshift Clusters as required

- kustomize build ./servicemesh/ --enable-alpha-plugins | oc apply -f -

