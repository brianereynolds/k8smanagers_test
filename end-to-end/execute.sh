#!/bin/bash

prompt() {
    local answer
    read -p "$1 Do you wish to proceed (y/n): " answer
    while [ "$answer" != "y" ]; do
        echo "Please enter 'y' to proceed."
        read -p "Do you want to proceed? (y/n): " answer
    done
    echo "Proceeding with the script..."
}

check() {
    # Execute the command passed as arguments to this function
    "$@"

    # Capture the return code of the executed command
    local return_code=$?

    # Check the return code and print a message based on it
    if [ $return_code -eq 0 ]; then
        echo "Command executed successfully."
    else
        echo "Command failed with return code $return_code."
    fi

    # Return the same return code
    return $return_code
}

NP_CONFIG_NAME="k8smanagers-e2e-nodepoolmanager"
WL_CONFIG_NAME="k8smanagers-e2e-workloadmanager"
DEPLOYMENT_NAME="e2e-deployment"

# Create 2 new node pools at the same version of Control Plane

cat <<EOF | kubectl -n $OPS_NS apply -f -
apiVersion: k8smanagers.greyridge.com/v1
kind: NodePoolManager
metadata:
  labels:
    app.kubernetes.io/name: nodepoolmanager
    app.kubernetes.io/managed-by: kustomize
  name: $NP_CONFIG_NAME
spec:
  subscriptionId: $SUB
  resourceGroup: $RGROUP
  clusterName: $CLUSTER
  retryOnError: false
  testMode: false

  nodePools:
    - name: "testpool1"
      properties: {
        orchestratorVersion: $CLUSTER_CP_VERSION,
        vmSize: "Standard_DS2_v2",
        enableAutoScaling: true,
        minCount: 0,
        maxCount: 1,
        "nodeLabels": {
          "pasx/node": "pool1"
        }
      }
    - name: "testpool2"
      properties: {
        orchestratorVersion: $CLUSTER_CP_VERSION,
        vmSize: "Standard_DS2_v2",
        enableAutoScaling: true,
        minCount: 0,
        maxCount: 1,
        nodeLabels: {
          "pasx/node": "pool2"
        }
      }
EOF

prompt "Check if node pools have been created."

# Create new Deployment and put onto pool1
cat <<EOF | kubectl -n $APP_NS apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $DEPLOYMENT_NAME
  namespace: $APP_NS
spec:
  replicas: 1
  selector:
    matchLabels:
      app: e2e-test
  template:
    metadata:
      labels:
        app: e2e-test
    spec:
      containers:
      - name: e2e-container
        image: nginx:latest
        ports:
        - containerPort: 80
      nodeSelector:
        pasx/node: "pool1"
EOF

prompt "Check if a Deployment called \"$DEPLOYMENT_NAME\" is ready and scheduled in pool1."

# Use Workload manager to move this to the other node pool
cat <<EOF | kubectl -n $OPS_NS apply -f -
apiVersion: k8smanagers.greyridge.com/v1
kind: WorkloadManager
metadata:
  labels:
    app.kubernetes.io/name: workloadmanager
    app.kubernetes.io/managed-by: kustomize
  name: $WL_CONFIG_NAME
spec:
  subscriptionId: $SUB
  resourceGroup: $RGROUP
  clusterName: $CLUSTER
  retryOnError: false
  testMode: false

  procedures:
    - description: "move-workloads"
      type: "deployment"
      namespace: $APP_NS
      workloads:
        - $DEPLOYMENT_NAME
      selector:
        key: "pasx/node"
        initial: "pool1"
        target: "pool2"
      timeout: 600
EOF

prompt "Check if a Deployment called \"$DEPLOYMENT_NAME\" has moved to pool2."

# Delete APP
kubectl delete deployment -n $APP_NS $DEPLOYMENT_NAME

prompt "Check that the \"$DEPLOYMENT_NAME\" Deployment has been deleted."

# Delete NPs
cat <<EOF | kubectl -n $OPS_NS apply -f -
apiVersion: k8smanagers.greyridge.com/v1
kind: NodePoolManager
metadata:
  labels:
    app.kubernetes.io/name: nodepoolmanager
    app.kubernetes.io/managed-by: kustomize
  name: $NP_CONFIG_NAME
spec:
  subscriptionId: $SUB
  resourceGroup: $RGROUP
  clusterName: $CLUSTER
  retryOnError: false
  testMode: false

  nodePools:
    - name: "testpool1"
      action: "delete"
    - name: "testpool2"
      action: "delete"
EOF

prompt "Check if node pools have been deleted."

echo "Deleting $NP_CONFIG_NAME"
kubectl -n $OPS_NS delete NodePoolManager $NP_CONFIG_NAME
echo "Deleting $WL_CONFIG_NAME"
kubectl -n $OPS_NS delete WorkloadManager $WL_CONFIG_NAME