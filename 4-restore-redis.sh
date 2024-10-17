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

#9.5.5. Ensuring information consistency between backend and system
#9.5.5.1. Managing the deployment configuration for backend-redis

echo "Passo 1"

oc get configmap redis-config -o yaml > /tmp/tmp3.yaml
echo "Passo 2"
sed -i 's/save /#save /g' /tmp/tmp3.yaml
echo "Passo 3"
sed -i 's/appendonly yes/appendonly no/g' /tmp/tmp3.yaml
echo "Passo 4"
oc apply -f /tmp/tmp3.yaml

echo "Passo 5"
oc rollout latest dc/backend-redis
echo "Passo 6"
oc rollout status dc/backend-redis

echo "Passo 7"
oc rsh $(oc get pods -l 'deploymentConfig=backend-redis' -o json | jq '.items[0].metadata.name' -r) bash -c 'mv ${HOME}/data/dump.rdb ${HOME}/data/dump.rdb-old'
echo "Passo 8"
oc rsh $(oc get pods -l 'deploymentConfig=backend-redis' -o json | jq '.items[0].metadata.name' -r) bash -c 'mv ${HOME}/data/appendonly.aof ${HOME}/data/appendonly.aof-old'
echo "Passo 9"
oc cp ./dump/backend-redis-dump.rdb $(oc get pods -l 'deploymentConfig=backend-redis' -o json | jq '.items[0].metadata.name' -r):/var/lib/redis/data/dump.rdb

echo "Passo 10"
oc rollout latest dc/backend-redis
echo "Passo 11"
oc rollout status dc/backend-redis

echo "Passo 12"
oc rsh $(oc get pods -l 'deploymentConfig=backend-redis' -o json | jq '.items[0].metadata.name' -r) bash -c 'redis-cli BGREWRITEAOF'

echo "Passo 13"
oc rsh $(oc get pods -l 'deploymentConfig=backend-redis' -o json | jq '.items[0].metadata.name' -r) bash -c 'redis-cli info' | grep aof_rewrite_in_progress

#14-Uncomment SAVE commands in the redis-config configmap:
echo "Passo 14"
oc get configmap redis-config -o yaml > /tmp/tmp3.yaml
echo "Passo 15"
sed -i 's/#save /save /g' /tmp/tmp3.yaml
echo "Passo 16"
sed -i 's/appendonly no/appendonly yes/g'  /tmp/tmp3.yaml
echo "Passo 17"
oc apply -f /tmp/tmp3.yaml

echo "Passo 18"
oc rollout latest dc/backend-redis
echo "Passo 19"
oc rollout status dc/backend-redis

#9.5.5.2. Managing the deployment configuration for system-redis
echo "Passo 20"
oc get configmap redis-config -o yaml > /tmp/tmp4.yaml
echo "Passo 21"
sed -i 's/save /#save /g' /tmp/tmp4.yaml
echo "Passo 22"
sed -i 's/appendonly yes/appendonly no/g' /tmp/tmp4.yaml
echo "Passo 23"
oc apply -f /tmp/tmp4.yaml

echo "Passo 24"
oc rollout latest dc/system-redis
echo "Passo 25"
oc rollout status dc/system-redis

echo "Passo 26"
oc rsh $(oc get pods -l 'deploymentConfig=system-redis' -o json | jq '.items[0].metadata.name' -r) bash -c 'mv ${HOME}/data/dump.rdb ${HOME}/data/dump.rdb-old'
echo "Passo 27"
oc rsh $(oc get pods -l 'deploymentConfig=system-redis' -o json | jq '.items[0].metadata.name' -r) bash -c 'mv ${HOME}/data/appendonly.aof ${HOME}/data/appendonly.aof-old'
echo "Passo 28"
oc cp ./dump/system-redis-dump.rdb $(oc get pods -l 'deploymentConfig=system-redis' -o json | jq '.items[0].metadata.name' -r):/var/lib/redis/data/dump.rdb

echo "Passo 28"
oc rollout latest dc/system-redis
echo "Passo 30"
oc rollout status dc/system-redis

echo "Passo 31"
oc rsh $(oc get pods -l 'deploymentConfig=system-redis' -o json | jq '.items[0].metadata.name' -r) bash -c 'redis-cli BGREWRITEAOF'
echo "Passo 32"
oc rsh $(oc get pods -l 'deploymentConfig=system-redis' -o json | jq '.items[0].metadata.name' -r) bash -c 'redis-cli info' | grep aof_rewrite_in_progress

echo "Passo 33"
oc get configmap redis-config -o yaml > /tmp/tmp5.yaml
echo "Passo 34"
sed -i 's/#save /save /g' /tmp/tmp5.yaml
echo "Passo 35"
sed -i 's/appendonly no/appendonly yes/g' /tmp/tmp5.yaml
echo "Passo 36"
oc apply -f /tmp/tmp5.yaml

echo "Passo 37"
oc rollout latest dc/system-redis
echo "Passo 38"
oc rollout status dc/system-redis