#!/bin/bash

# 9.5.4. Restoring zync-database
# 9.5.4.1. Operator-based deployments

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

oc project "$namespace"

echo "Restoring zync-database using Deployment"

# === 1. replay rollout ===
echo "Passo 0: Restart zync-database deployment"
oc rollout restart deployment/zync-database
oc rollout status deployment/zync-database

# === 2. Save original replicas ===
echo "Passo 1: Store the number of replicas:"
ZYNC_SPEC=$(oc get APIManager/${DEPLOYMENT_NAME} -o json | jq -r '.spec.zync')

# === 3. Scale to 0 ===
echo "Passo 2: Scale down the zync Deployment to 0 pods:"
oc patch APIManager/${DEPLOYMENT_NAME} --type merge -p '{"spec": {"zync": {"appSpec": {"replicas": 0}, "queSpec": {"replicas": 0}}}}'

# === 4. Copy dump file ===
echo "Passo 3: Copy the zync database dump to the zync-database pod:"
POD=$(oc get pods -l 'deployment=zync-database' -o json | jq -r '.items[0].metadata.name')
oc cp ./dump/zync-database-backup.gz "$POD":/var/lib/pgsql/

# === 5. Decompress ===
echo "Passo 4: Decompress the backup file:"
oc rsh "$POD" bash -c 'gzip -d ${HOME}/zync-database-backup.gz'

# === 6. Restore backup ===
echo "Passo 5: Restore zync database backup file:"
oc rsh "$POD" bash -c 'psql zync_production -f ${HOME}/zync-database-backup'

# === 7. Scale back ===
echo "Passo 6: Restore to the original count of replicas:"
oc patch APIManager/${DEPLOYMENT_NAME} --type merge -p '{"spec": {"zync": {"appSpec": {"replicas": 1}}}}'
oc patch APIManager/${DEPLOYMENT_NAME} --type merge -p '{"spec": {"zync": {"queSpec": {"replicas": 1}}}}'
