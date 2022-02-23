# servicemesh-demos

## ServiceMesh Demos

### Summary of what this repo contains
Repo provides automation to test/demo interesting connectivity(service mesh e.t.c) and other tools.Repo contains multiple use cases to test in the use case folder in this repo. Each use case has the automation and steps to accomplish it's demo/test.

### Pre-Requisites

- oc client >= 4.8
- [Openshift Policy Generator Kustomize Plugin](https://github.com/open-cluster-management/policy-generator-plugin#as-a-kustomize-plugin)

---

### - Install ACM Operator and create ACM Hub

- Operator via [Gitops](https://github.com/redhat-cop/gitops-catalog/tree/main/advanced-cluster-management/operator)
- Hub via [Gitops](https://github.com/redhat-cop/gitops-catalog/tree/main/advanced-cluster-management/instance)
- Sample Script(Might not be updated) - ./acm/install.sh

### Install Openshift-gitops Operator on all Openshift Clusters

- ```kustomize build ./operators/openshift-gitops/base --enable-alpha-plugins | oc apply -f -```

### Install Openshift ElasticSearch Operator on all Openshift Clusters

- ```kustomize build ./operators/elasticsearch/base --enable-alpha-plugins | oc apply -f -```

### Install Openshift Jaeger Operator on all Openshift Clusters  

- ```kustomize build ./operators/jaeger/base --enable-alpha-plugins | oc apply -f -```
  
### Install Openshift Kiali Operator on all Openshift Clusters -->

- ```kustomize build ./operators/kiali/base --enable-alpha-plugins | oc apply -f -```

### Install Openshift Virtualization Operator on all Openshift Clusters

- ```kustomize build ./operators/openshift-virtualization/base --enable-alpha-plugins | oc apply -f -```

### Install Openshift Service Mesh Operator on all Openshift Clusters

- ```kustomize build ./operators/servicemesh/base --enable-alpha-plugins | oc apply -f -```

### Install the Traffic Image Build. Container Image is used to generate traffic for servicemesh use cases

- ```kustomize build ./traffic-image-build/base --enable-alpha-plugins | oc apply -f -```

### Give Openshift Gitops Permission on Service Mesh and Virtualization Namespace

```oc label namespace openshift-cnv argocd.argoproj.io/managed-by=openshift-gitops```  
```oc label namespace istio-system argocd.argoproj.io/managed-by=openshift-gitops```

<!--### If using CNV on a virtual environment enable software emulation

```CSV_NAME=$(oc get csv -n openshift-cnv -l operators.coreos.com/kubevirt-hyperconverged.openshift-cnv='' -o name)```
-->
---

### Install Smesh with VM's Use Case

1 Steps in ./use-cases/smesh-with-vms/README



