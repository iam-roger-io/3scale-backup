#!/bin/bash

while getopts "n:" opt; do
  case $opt in
    n) namespace=$OPTARG ;;
    *) echo "Uso: $0 -n <namespace>" && exit 1 ;;
  esac
done

if [ -z "$namespace" ]; then
  echo "Erro: Nome da namespace não foi informado."
  echo "Uso: $0 -n <namespace>"
  exit 1
fi

oc project "$namespace"

##
## 9.5.5. Ensuring consistency backend/system
##

echo "Step 1/38"
oc get configmap redis-config -o yaml > /tmp/tmp3.yaml

echo "Step 2/38"
sed -i 's/save /#save /g' /tmp/tmp3.yaml

echo "Step 3/38"
sed -i 's/appendonly yes/appendonly no/g' /tmp/tmp3.yaml

echo "Step 4/38"
oc apply -f /tmp/tmp3.yaml

echo "Step 5/38"
oc rollout restart deployment/backend-redis

echo "Step 6/38"
oc rollout status deployment/backend-redis

echo "Step 7/38"
oc rsh $(oc get pods -l 'deployment=backend-redis' -o json | jq -r '.items[0].metadata.name') bash -c 'mv ${HOME}/data/dump.rdb ${HOME}/data/dump.rdb-old'

echo "Step 8/38"
oc rsh $(oc get pods -l 'deployment=backend-redis' -o json | jq -r '.items[0].metadata.name') bash -c 'mv ${HOME}/data/appendonly.aof ${HOME}/data/appendonly.aof-old'

echo "Step 9/38"
oc cp ./dump/backend-redis-dump.rdb $(oc get pods -l 'deployment=backend-redis' -o json | jq -r '.items[0].metadata.name'):/var/lib/redis/data/dump.rdb

echo "Step 10/38"
oc rollout restart deployment/backend-redis

echo "Step 11/38"
oc rollout status deployment/backend-redis

echo "Step 12/38"
oc rsh $(oc get pods -l 'deployment=backend-redis' -o json | jq -r '.items[0].metadata.name') bash -c 'redis-cli BGREWRITEAOF'

echo "Step 13/38"
oc rsh $(oc get pods -l 'deployment=backend-redis' -o json | jq -r '.items[0].metadata.name') bash -c 'redis-cli info' | grep aof_rewrite_in_progress

# system-redis
echo "Step 20/38"
oc get configmap redis-config -o yaml > /tmp/tmp4.yaml

echo "Step 21/38"
sed -i 's/save /#save /g' /tmp/tmp4.yaml

echo "Step 22/38"
sed -i 's/appendonly yes/appendonly no/g' /tmp/tmp4.yaml

echo "Step 23/38"
oc apply -f /tmp/tmp4.yaml

echo "Step 24/38"
oc rollout restart deployment/system-redis

echo "Step 25/38"
oc rollout status deployment/system-redis

echo "Step 26/38"
oc rsh $(oc get pods -l 'deployment=system-redis' -o json | jq -r '.items[0].metadata.name') bash -c 'mv ${HOME}/data/dump.rdb ${HOME}/data/dump.rdb-old'

echo "Step 27/38"
oc rsh $(oc get pods -l 'deployment=system-redis' -o json | jq -r '.items[0].metadata.name') bash -c 'mv ${HOME}/data/appendonly.aof ${HOME}/data/appendonly.aof-old'

echo "Step 28/38"
oc cp ./dump/system-redis-dump.rdb $(oc get pods -l 'deployment=system-redis' -o json | jq -r '.items[0].metadata.name'):/var/lib/redis/data/dump.rdb

echo "Step 29/38"
oc rollout restart deployment/system-redis

echo "Step 30/38"
oc rollout status deployment/system-redis

echo "Step 31/38"
oc rsh $(oc get pods -l 'deployment=system-redis' -o json | jq -r '.items[0].metadata.name') bash -c 'redis-cli BGREWRITEAOF'

echo "Step 32/38"
oc rsh $(oc get pods -l 'deployment=system-redis' -o json | jq -r '.items[0].metadata.name') bash -c 'redis-cli info' | grep aof_rewrite_in_progress

echo "Step 33/38"
oc get configmap redis-config -o yaml > /tmp/tmp5.yaml

echo "Step 34/38"
sed -i 's/#save /save /g' /tmp/tmp5.yaml

echo "Step 35/38"
sed -i 's/appendonly no/appendonly yes/g' /tmp/tmp5.yaml

echo "Step 36/38"
oc apply -f /tmp/tmp5.yaml

echo "Step 37/38"
oc rollout restart deployment/system-redis

echo "Step 38/38"
oc rollout status deployment/system-redis
