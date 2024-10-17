#!/bin/bash

# Verifica se o nome da namespace foi passado
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

oc project $namespace

# 9.5.5. Ensuring information consistency between backend and system
# 9.5.5.1. Managing the deployment configuration for backend-redis

echo "Step 1/38"
oc get configmap redis-config -o yaml > /tmp/tmp3.yaml

echo "Step 2/38"
sed -i 's/save /#save /g' /tmp/tmp3.yaml

echo "Step 3/38"
sed -i 's/appendonly yes/appendonly no/g' /tmp/tmp3.yaml

echo "Step 4/38"
oc apply -f /tmp/tmp3.yaml

echo "Step 5/38"
oc rollout latest dc/backend-redis

echo "Step 6/38"
oc rollout status dc/backend-redis

echo "Step 7/38"
oc rsh $(oc get pods -l 'deploymentConfig=backend-redis' -o json | jq '.items[0].metadata.name' -r) bash -c 'mv ${HOME}/data/dump.rdb ${HOME}/data/dump.rdb-old'

echo "Step 8/38"
oc rsh $(oc get pods -l 'deploymentConfig=backend-redis' -o json | jq '.items[0].metadata.name' -r) bash -c 'mv ${HOME}/data/appendonly.aof ${HOME}/data/appendonly.aof-old'

echo "Step 9/38"
oc cp ./dump/backend-redis-dump.rdb $(oc get pods -l 'deploymentConfig=backend-redis' -o json | jq '.items[0].metadata.name' -r):/var/lib/redis/data/dump.rdb

echo "Step 10/38"
oc rollout latest dc/backend-redis

echo "Step 11/38"
oc rollout status dc/backend-redis

echo "Step 12/38"
oc rsh $(oc get pods -l 'deploymentConfig=backend-redis' -o json | jq '.items[0].metadata.name' -r) bash -c 'redis-cli BGREWRITEAOF'

echo "Step 13/38"
oc rsh $(oc get pods -l 'deploymentConfig=backend-redis' -o json | jq '.items[0].metadata.name' -r) bash -c 'redis-cli info' | grep aof_rewrite_in_progress

# 14-Uncomment SAVE commands in the redis-config configmap:
echo "Step 14/38"
oc get configmap redis-config -o yaml > /tmp/tmp3.yaml

echo "Step 15/38"
sed -i 's/#save /save /g' /tmp/tmp3.yaml

echo "Step 16/38"
sed -i 's/appendonly no/appendonly yes/g' /tmp/tmp3.yaml

echo "Step 17/38"
oc apply -f /tmp/tmp3.yaml

echo "Step 18/38"
oc rollout latest dc/backend-redis

echo "Step 19/38"
oc rollout status dc/backend-redis

# 9.5.5.2. Managing the deployment configuration for system-redis
echo "Step 20/38"
oc get configmap redis-config -o yaml > /tmp/tmp4.yaml

echo "Step 21/38"
sed -i 's/save /#save /g' /tmp/tmp4.yaml

echo "Step 22/38"
sed -i 's/appendonly yes/appendonly no/g' /tmp/tmp4.yaml

echo "Step 23/38"
oc apply -f /tmp/tmp4.yaml

echo "Step 24/38"
oc rollout latest dc/system-redis

echo "Step 25/38"
oc rollout status dc/system-redis

echo "Step 26/38"
oc rsh $(oc get pods -l 'deploymentConfig=system-redis' -o json | jq '.items[0].metadata.name' -r) bash -c 'mv ${HOME}/data/dump.rdb ${HOME}/data/dump.rdb-old'

echo "Step 27/38"
oc rsh $(oc get pods -l 'deploymentConfig=system-redis' -o json | jq '.items[0].metadata.name' -r) bash -c 'mv ${HOME}/data/appendonly.aof ${HOME}/data/appendonly.aof-old'

echo "Step 28/38"
oc cp ./dump/system-redis-dump.rdb $(oc get pods -l 'deploymentConfig=system-redis' -o json | jq '.items[0].metadata.name' -r):/var/lib/redis/data/dump.rdb

echo "Step 29/38"
oc rollout latest dc/system-redis

echo "Step 30/38"
oc rollout status dc/system-redis

echo "Step 31/38"
oc rsh $(oc get pods -l 'deploymentConfig=system-redis' -o json | jq '.items[0].metadata.name' -r) bash -c 'redis-cli BGREWRITEAOF'

echo "Step 32/38"
oc rsh $(oc get pods -l 'deploymentConfig=system-redis' -o json | jq '.items[0].metadata.name' -r) bash -c 'redis-cli info' | grep aof_rewrite_in_progress

echo "Step 33/38"
oc get configmap redis-config -o yaml > /tmp/tmp5.yaml

echo "Step 34/38"
sed -i 's/#save /save /g' /tmp/tmp5.yaml

echo "Step 35/38"
sed -i 's/appendonly no/appendonly yes/g' /tmp/tmp5.yaml

echo "Step 36/38"
oc apply -f /tmp/tmp5.yaml

echo "Step 37/38"
oc rollout latest dc/system-redis

echo "Step 38/38"
oc rollout status dc/system-redis
