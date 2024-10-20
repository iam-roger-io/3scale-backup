#!/bin/bash

# 9.5.4. Restoring zync-database
# 9.5.4.1. Operator-based deployments

# Verifica se o nome da namespace e o nome do deployment foram passados
while getopts "n:d:" opt; do
  case $opt in
    n) namespace=$OPTARG ;;
    d) DEPLOYMENT_NAME=$OPTARG ;;
    *) echo "Uso: $0 -n <namespace> -d <deployment_name>" && exit 1 ;;
  esac
done

if [ -z "$namespace" ]; then
  echo "Erro: Nome da namespace não foi informado."
  echo "Uso: $0 -n <namespace> -d <deployment_name>"
  exit 1
fi

if [ -z "$DEPLOYMENT_NAME" ]; then
  echo "Erro: Nome do deployment não foi informado."
  echo "Uso: $0 -n <namespace> -d <deployment_name>"
  exit 1
fi

oc project $namespace

# 9.5.4. Restoring zync-database
# 9.5.4.1. Operator-based deployments

oc rollout latest dc/zync-database
oc rollout status dc/zync-database

echo "Passo 1: Store the number of replicas:"
ZYNC_SPEC=$(oc get APIManager/${DEPLOYMENT_NAME} -o json | jq -r '.spec.zync')

echo "Passo 2: Scale down the zync DeploymentConfig to 0 pods:"
oc patch APIManager/${DEPLOYMENT_NAME} --type merge -p '{"spec": {"zync": {"appSpec": {"replicas": 0}, "queSpec": {"replicas": 0}}}}'

echo "Passo 3: Copy the zync database dump to the zync-database pod:"
oc cp ./dump/zync-database-backup.gz $(oc get pods -l 'deploymentConfig=zync-database' -o json | jq '.items[0].metadata.name' -r):/var/lib/pgsql/

echo "Passo 4: Decompress the backup file:"
oc rsh $(oc get pods -l 'deploymentConfig=zync-database' -o json | jq -r '.items[0].metadata.name') bash -c 'gzip -d ${HOME}/zync-database-backup.gz'

echo "Passo 5: Restore zync database backup file:"
oc rsh $(oc get pods -l 'deploymentConfig=zync-database' -o json | jq -r '.items[0].metadata.name') bash -c 'psql zync_production -f ${HOME}/zync-database-backup'

echo "Passo 6: Restore to the original count of replicas:"
oc patch APIManager/${DEPLOYMENT_NAME} --type merge -p '{"spec": {"zync": {"appSpec": {"replicas": 1}}}}'
oc patch APIManager/${DEPLOYMENT_NAME} --type merge -p '{"spec": {"zync": {"queSpec": {"replicas": 1}}}}'
