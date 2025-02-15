# k8smanagers_test
Tests for K8S managers

# Intro
The root contains scripts for per-cluster env vars. Once this has been executed, then run the scripts respective test case folder.

# End-to-end Test

## Node Selector
This test creates 2 node pools, each with a different node selector. It creates a Deployment and schedules it in node pool #1.
It then uses the workloadmanager to move the deployment to node pool #2. 

Verification activities are all non-AI (e.g a human). The script will pause to allow time to check.

```
cd end-to-end/nodeSelector

./1_init.sh

./2_execute.sh

./3_term.sh
```