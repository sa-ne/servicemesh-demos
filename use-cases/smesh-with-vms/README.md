# ServiceMesh with Openshift Virtualization

Status: Ready  
This use case shows how to run a microservice application in a mixed container and virtual machine environment
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
Deploy the smesh-with-vms application.Repo also serves daual purpose for showing Deployment Methods for combining ACM and Openshift GitOps together.There are several ways to create the application with or without ACM and Openshift Gitops. Choose one of the below methods to deploy the smesh-with-vms application.

1 Deploy application manifests directly without ACM or Gitops  
2 Deploy application manifests using Openshift Gitops Application for a Single Cluster  
3 Deploy application manifests using Openshift Gitops/ArgoCD Application Object in every Openshift cluster using ACM  
4 Deploy the application manifests using OpenShift GitOps/ArgoCD ApplicationSet deployed from a Single Openshift GitOps Cluster to multiple Openshift Clusters via ACM.
5 Create application manifests using ACM directly.

## 1) Deploy Application manifests directly without using Gitops/ACM
Deploy the smesh with vm's application directly to Openshift without using Red Hat Advanced Cluster Management(ACM) or Openshift GitOps.

### Prerequisites

- [Install all required Operators and Traffic Generation Image](https://github.com/sa-ne/servicemesh-demos#--install-acm-operator-and-create-acm-hub)
- Traffic Generator Image can be installed without ACM  
  `oc apply -k ./traffic-image-build/base`

### Steps

1 Clone this Repo  
2 Change Directory into the cloned folder  
3 Create Application Manifests using OC and Kustomize directly without ACM or Gitops

- `kustomize build ./use-cases/smesh-with-vms/infra/deployables/overlays/manifests/ | oc create -f -`

- `kustomize build ./use-cases/smesh-with-vms/app/deployables/overlays/manifests/ | oc create -f - -n smesh-with-vms`
- `kustomize build ./use-cases/smesh-with-vms/traffic-generator/deployables/overlays/manifests/`

## 2) Deploy Application using Openshift Gitops
Deploy the application using openshift GitOps/ArgoCD Application Objects.To deploy this on multiple clusters we would need to create the application object(run below steps) on every Openshift Cluster manually.This also requires that every cluster has the Openshift GitOps/ArgoCD Operator Installed.

### Prerequisites

- [Install all required Operators and Traffic Generation Image](https://github.com/sa-ne/servicemesh-demos#--install-acm-operator-and-create-acm-hub)
- [Traffic Generator Image is required](https://github.com/sa-ne/servicemesh-demos#install-the-traffic-image-build-container-image-is-used-to-generate-traffic-for-servicemesh-use-cases)  

### Steps

1 Clone this Repo  
2 Change Directory into the cloned folder  
3 Create ArgoCD Application Manifests and view Openshift GitOps Dashboard to view.

4 Create ArgoCD Application for Infrastructure required by use case

`oc apply -k ./use-cases/smesh-with-vms/infra`

5 Create ArgoCD Application for Bookinfo Application Components  
`oc apply -k ./use-cases/smesh-with-vms/app`

6 Create ArgoCD Application for Traffic Generation  
 `oc apply -k ./use-cases/smesh-with-vms/traffic-generator/`

## 3) Deploy application manifests using Openshift Gitops/ArgoCD Application Object in every Openshift cluster using ACM
We can also use Red Hat ACM to deploy the Openshift GitOps/ArgoCD Application Objects on every Openshift Cluster.The advantage of this method over option 2 above is that ACM automatically add new openshift clusters into a single ArgoCD/Openshift GitOps Cluster. This also requires that every cluster has the Openshift GitOps/ArgoCD Operator Installed.

### Prerequisites

- [Install all required Operators and Traffic Generation Image](https://github.com/sa-ne/servicemesh-demos#--install-acm-operator-and-create-acm-hub)

- [Traffic Generator Image is required](https://github.com/sa-ne/servicemesh-demos#install-the-traffic-image-build-container-image-is-used-to-generate-traffic-for-servicemesh-use-cases)  

### Steps

1 Clone this Repo  
2 Change Directory into the cloned folder  
3 Create ArgoCD Application Manifests using ACM, you can login to ACM Dashoard to view.
```oc apply -k ./use-cases/smesh-with-vms/create_via_acm_gitops/```

## 4) Deploy the application manifests using Openshift GitOps/ArgoCD ApplicationSet deployed from a Single Openshift GitOps Cluster to multiple Openshift Clusters via ACM.
We can also use Red Hat ACM to add control of multiple Openshift Clusters into a single Openshift GitOps/ArgoCD Operator so it can handle the deployment of our applications to all the Openshift clusters under it's control via an ApplicationSet.  
This also means that we only require 1 Openshift GitOps/ArgoCD Operator Installed and that single operator is the source of all our deployments.

### Prerequisites

- [Install all required Operators and Traffic Generation Image](https://github.com/sa-ne/servicemesh-demos#--install-acm-operator-and-create-acm-hub)

- [Traffic Generator Image is required](https://github.com/sa-ne/servicemesh-demos#install-the-traffic-image-build-container-image-is-used-to-generate-traffic-for-servicemesh-use-cases)  

- Create an Openshift GitOpsCLuster Object to add all Openshift Clusters into the same OpenShift GitOps Cluster/Operator.This example assumes the local cluster is used as the central GitOps Operator.

### Steps
1 Deploy the ACM GitOps Cluster Object  
 `kustomize build ./operators/acm/acm-openshift-gitops/ --enable-alpha-plugins | oc create -f -`

2 Label Required ManagedClusters to add them to the ManagedClusterSet- Sample Below  
 `oc label managedcluster/<CLUSTER_NAME> cluster.open-cluster-management.io/clusterset=smesh-demo-clusters --overwrite=true`

OR

Label all ManagedClusters including the local cluster  
 `for mc in $(oc get managedclusters -A -o name | grep -v "local-cluster");do oc label $mc cluster.open-cluster-management.io/clusterset=smesh-demo-clusters --overwrite=true;done`

3 Label Required ManagedClusters to add them to the ArgoCD Hub - Sample Below. Note: except you are changing the default gitops don't label the local cluster here as its added to the default Openshift Gitops Cluster.  
 `oc label managedcluster/<CLUSTER_NAME> demo-usage=smesh-demo-clusters --overwrite=true`

OR

Label all ManagedClusters except the local cluster  
 `for mc in $(oc get managedclusters -A -o name | grep -v "local-cluster");do oc label $mc demo-usage=smesh-demo-clusters --overwrite=true;done`

4 Confirm clusters are present in Openshift Gitops either via the UI or CLI. See ./templates/generate-smcp.sh script for sample.

```bash
export ARGOCD_USERNAME=admin
export ARGOCD_PASSWORD=$(oc get secrets/openshift-gitops-cluster -n openshift-gitops -o jsonpath='{.data.admin\.password}'| base64 -d)
export ARGOCD_URL=$(oc get route/openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}')
argocd login $ARGOCD_URL --username $ARGOCD_USERNAME --password $ARGOCD_PASSWORD --insecure && argocd cluster list
```

5 Create the ApplicationSet Objects required for deployment  
```oc apply -k ./use-cases/smesh-with-vms/create_via_applicationset``` 

## 5) Create application manifests using ACM directly.
Create the Application via ACM Applications directly and allow ACM handle. 
Note: To create this correctly user running must have [subscription admin privileges](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.4/html/applications/managing-applications#granting-subscription-admin-privilege)  

### Prerequisites

- [Install all required Operators and Traffic Generation Image](https://github.com/sa-ne/servicemesh-demos#--install-acm-operator-and-create-acm-hub)

- [Traffic Generator Image is required](https://github.com/sa-ne/servicemesh-demos#install-the-traffic-image-build-container-image-is-used-to-generate-traffic-for-servicemesh-use-cases)  

### Steps

1 Clone this Repo  
2 Change Directory into the cloned folder  
3 Create application manifests using ACM directly  
```oc apply -k ./use-cases/smesh-with-vms/create_via_acm_application_manifests```  

## Known Problems

- The servicemeshmesh sync does not always work correctly or does not inject istio-proxy into pods.If this happens delete the servicemeshmemberroll in istio-system and allow gitops re-create it.
- The VM takes a bit long to boot and start handling traffic, might need close to 10 mins.Plan to update VM Image with a faster boot version.
