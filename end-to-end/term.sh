
helm delete nodepoolmanager  -n $OPS_NS

helm delete workloadmanager  -n $OPS_NS

kubectl delete ns $OPS_NS
kubectl delete ns $APP_NS
