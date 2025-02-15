# k8smanagers_test
Tests for K8S managers, nodepool and workload managers

# Intro
The root contains scripts for per-cluster env vars. Once this has been executed, then run init.sh in respective test case.

# End-to-end Test
```
cd end-to-end

./1_init.sh

./2_execute.sh

./3_term.sh
```