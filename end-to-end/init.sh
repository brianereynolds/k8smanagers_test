az account set --subscription $SUB
az aks get-credentials --resource-group $RGROUP  --name $CLUSTER --overwrite-existing

kubectl create ns $OPS_NS
kubectl create ns $APP_NS

helm repo add k8smanagers https://k8smanagers.blob.core.windows.net/helm/
helm install nodepoolmanager k8smanagers/nodepoolmanager -n $OPS_NS
helm install workloadmanager k8smanagers/workloadmanager -n $OPS_NS




