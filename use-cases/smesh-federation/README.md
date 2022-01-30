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

- [Install all required Operators and Traffic Generation Image](https://github.com/sa-ne/servicemesh-demos#status---working-but-no-checks-for-pre-requisites-yet-commands-might-have-to-be-run-multiple-times)
  
- Create a Gitops Cluster in ACM to allow ArgoCD Multi-Cluster Registration.  
  The default manifests used are in [same-repo](https://github.com/sa-ne/servicemesh-demos/tree/main/operators/acm/argo-deployables).The manifests uses the openshift local-cluster as the hub Argo cluster and will create a ManagedClusterSet and add managed clusters based on labels to a central ArgoCD(Default - Local Openshift Cluster).

  1 Deploy the ACM GitOps Cluster Object  
    ```kustomize build ./operators/acm/acm-openshift-gitops/ --enable-alpha-plugins | oc create -f -```

  2 Label Required ManagedClusters to add them to the ManagedClusterSet- Sample Below  
  ```oc label managedcluster/cluster2 cluster.open-cluster-management.io/clusterset=smesh-demo-clusters --overwrite=true```
  
  3 Label Required ManagedClusters to add them to the ArgoCD Hub - Sample Below. Note: except you are changing the default gitops don't label the local cluster here as its added to the default Openshift Gitops Cluster.  
  ```oc label managedcluster/cluster2 demo-usage=smesh-demo-clusters --overwrite=true```

