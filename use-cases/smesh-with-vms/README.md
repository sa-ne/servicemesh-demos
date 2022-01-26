# Smesh with VM's Use Case  

This use case shows how to run an microservice application in a mixed container and virtual machine environment
Application to be deployed is the popular bookinfo application used for servicemesh demos.
This demo will also show multiple ways on how to use Red Hat's Advanced Cluster Management Product and Openshift Gitops in different ways.

## Application Manifests have been broken down in 3 categories 

- smesh-with-vms[app]:  
  This includes manifests for the bookinfo application from upstream service mesh, service mesh destination rules, virtual machine template.
  
- smesh-with-vms[infra]:  
  This includes manifest for the servicemeshcontrolplane for Openshift, manifests for the Kubevirt Object and Rolebinding Objects.

- smesh-with-vms[traffic-generator]:  
  This includes manifests for the secondary app to generate simple traffic for the servicemesh.

---

## Deploy Application  

There are several ways to create the application with or without ACM and Openshift Gitops

1 Deploy application manifests directly without ACM or Gitops  
2 Deploy application manifests using Openshift Gitops Application for a Single Cluster

## 1) Deploy Application manifests directly without using Gitops/ACM

### Prerequisites  

- Install all required Operators and Traffic Generation Image
  
- Make sure Traffic Generator Pod is installed  
  ```oc apply -k ./traffic-image-build/base```

### Steps  

1 Clone this Repo  
2 Change Directory into the cloned folder  
3 Create Application Manifests using OC and Kustomize directly without ACM or Gitops 

- ```kustomize build ./use-cases/smesh-with-vms/infra/deployables/overlays/manifests/ | oc create -f -```  

- ```kustomize build ./use-cases/smesh-with-vms/app/deployables/overlays/manifests/ | oc create -f - -n smesh-with-vms```
  
- ```kustomize build ./use-cases/smesh-with-vms/traffic-generator/deployables/overlays/manifests/```

## 2) Deploy Application using Openshift Gitops

### Prerequisites 

- Install all required Operators and Traffic Generation Image

### Steps  

1 Clone this Repo  
2 Change Directory into the cloned folder  
3 Create ArgoCD Application Manifests and view Openshift GitOps Dashboard to view. 

- Make sure Traffic Generator Pod is installed  
  ```oc apply -k ./traffic-image-build/base```

1 Create ArgoCD Application for Infrastructure required by use case

  ```oc apply -k ./use-cases/smesh-with-vms/infra```

2 Create ArgoCD Application for Bookinfo Application Components  
```oc apply -k ./use-cases/smesh-with-vms/app```

3 Create ArgoCD Application for Traffic Generation  
  ```oc apply -k ./use-cases/smesh-with-vms/traffic-generator/```

<!-- 
### Prerequisites

- Make sure Openshift Gitops operator is installed see Openshift Gitops operator , see Repository readme [servicemesh-demos](https://github.com/sa-ne/servicemesh-demos)
  
### Steps

1 Clone this Repo  
2 Change Directory into the cloned folder  
3 Create Argo application to deploy manifests

``` bash
oc apply -k ./use-cases/smesh-with-vms/
```

## Deploy Application via ArgoCD but use ACM to create ArgoCD Application

1 Clone this Repo  
2 Change Directory into the cloned folder  
3 Change ACM Subscription Manifests to point to Application deployable manifests directly i.e apps.open-cluster-management.io/git-path is pointing to use-cases/smesh-with-vms/app or infra or traffic-generator /deployables for subscriptions in ./use-cases/smesh-with-vms/create_via_acm_gitops_per_cluster.
  Use sed to add:  
   ```find ./use-cases/smesh-with-vms/create_via_acm_gitops_per_cluster -name "subscription-*.yaml" -exec sed -i 's|\(use-cases/smesh-with-vms/.*$\)|\1/deployables|g' {} +```  
4 Create the ACM Application that will deploy and manage the application  
```oc apply -k ./use-cases/smesh-with-vms/create_via_acm_gitops_per_cluster```  
5 Remember to update ACM PlacmentRule to match Clusters Application should be installed in

## Create ArgoCD Application via ACM with ArgoCD per Cluster

```find ./use-cases/smesh-with-vms/create_via_acm_gitops_per_cluster -name "subscription-*.yaml" -exec sed -i 's|\(use-cases/smesh-with-vms/.*\)/deployables.*|\1|g' {} +```

1 ```kustomize build ./use-cases/smesh-with-vms/create_via_acm/ --enable-alpha-plugins | oc create -f -```


-->

## Known Problems

- The servicemeshmesh sync does not always work correctly or does not inject istio-proxy into pods.If this happens delete the servicemeshmemberroll in istio-system and allow gitops re-create it.
