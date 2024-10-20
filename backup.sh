#!/bin/bash

echo "########################################################################"
echo "## B A C K U P   F O R   3 S C A L E"
echo "## Starting backup of 3scale API Manager:"
echo "## Script for version 2.14"
echo "Reference documentation: https://docs.redhat.com/en/documentation/red_hat_3scale_api_management/2.14/html/operating_red_hat_3scale_api_management/threescale-backup-restore"
echo "########################################################################"

# Definir o formato de saída padrão como yaml
output_format="yaml"

# Verifica os parâmetros -n (namespace) e -o (formato de saída)
while getopts "n:o:" opt; do
  case $opt in
    n) namespace=$OPTARG ;;
    o) 
      if [[ "$OPTARG" == "yaml" || "$OPTARG" == "json" ]]; then
        output_format=$OPTARG
      else
        echo "Erro: O valor de -o deve ser 'yaml' ou 'json'."
        exit 1
      fi
      ;;
    *) echo "Uso: $0 -n <namespace> [-o <yaml|json>]" && exit 1 ;;
  esac
done

if [ -z "$namespace" ]; then
  echo "Erro: Nome da namespace não foi informado."
  echo "Uso: $0 -n <namespace> [-o <yaml|json>]"
  exit 1
fi

# Verifica se a pasta .ocp existe
if [ -d "./ocp" ]; then
    # Se existe, apaga a pasta
    rm -rf ./ocp
fi

if [ -d "./dump" ]; then
    # Se existe, apaga a pasta
    rm -rf ./dump
fi

echo "## 9.4.6: Backing up OpenShift secrets and ConfigMaps"
echo "Step 1: 9.4.6.1. OpenShift secrets "
mkdir -p ./ocp/secrets/

# Secrets
oc get secrets system-smtp -n "$namespace" -o "$output_format" | yq eval 'del(.metadata.creationTimestamp, .metadata.resourceVersion, .metadata.uid)' - > ./ocp/secrets/system-smtp.$output_format
oc get secrets system-seed -n "$namespace" -o "$output_format" | yq eval 'del(.metadata.creationTimestamp, .metadata.resourceVersion, .metadata.uid)' - >  ./ocp/secrets/system-seed.$output_format
oc get secrets system-database -n "$namespace" -o "$output_format" | yq eval 'del(.metadata.creationTimestamp, .metadata.resourceVersion, .metadata.uid)' - >   ./ocp/secrets/system-database.$output_format
oc get secrets backend-internal-api -n "$namespace" -o "$output_format" | yq eval 'del(.metadata.creationTimestamp, .metadata.resourceVersion, .metadata.uid)' - > ./ocp/secrets/backend-internal-api.$output_format
oc get secrets system-events-hook -n "$namespace" -o "$output_format" | yq eval 'del(.metadata.creationTimestamp, .metadata.resourceVersion, .metadata.uid)' - >  ./ocp/secrets/system-events-hook.$output_format
oc get secrets system-app -n "$namespace" -o "$output_format" | yq eval 'del(.metadata.creationTimestamp, .metadata.resourceVersion, .metadata.uid)' - >  ./ocp/secrets/system-app.$output_format
oc get secrets system-recaptcha -n "$namespace" -o "$output_format" | yq eval 'del(.metadata.creationTimestamp, .metadata.resourceVersion, .metadata.uid)' - >  ./ocp/secrets/system-recaptcha.$output_format
oc get secrets system-redis -n "$namespace" -o "$output_format" | yq eval 'del(.metadata.creationTimestamp, .metadata.resourceVersion, .metadata.uid)' - >  ./ocp/secrets/system-redis.$output_format
oc get secrets zync -n "$namespace" -o "$output_format" | yq eval 'del(.metadata.creationTimestamp, .metadata.resourceVersion, .metadata.uid)' - >  ./ocp/secrets/zync.$output_format
oc get secrets system-master-apicast -n "$namespace" -o "$output_format" | yq eval 'del(.metadata.creationTimestamp, .metadata.resourceVersion, .metadata.uid)' - >  ./ocp/secrets/system-master-apicast.$output_format

# Config Maps
mkdir -p ./ocp/configmap/
echo "Step 2: 9.4.6.2. ConfigMaps"
oc get configmaps system-environment -n "$namespace" -o "$output_format" | yq eval 'del(.metadata.creationTimestamp, .metadata.resourceVersion, .metadata.uid, .metadata.ownerReferences)' - >  ./ocp/configmap/system-environment.$output_format
oc get configmaps apicast-environment -n "$namespace" -o "$output_format" | yq eval 'del(.metadata.creationTimestamp, .metadata.resourceVersion, .metadata.uid, .metadata.ownerReferences)' - >  ./ocp/configmap/apicast-environment.$output_format

echo " "
echo "## 9.4: Backing up system databases"
mkdir ./dump
echo "Step 3: 9.4.1. Backing up system-mysql"
oc rsh -n "$namespace" $(oc get pods -n "$namespace" -l 'deploymentConfig=system-mysql' -o json | jq -r '.items[0].metadata.name') bash -c 'export MYSQL_PWD=${MYSQL_ROOT_PASSWORD}; mysqldump --single-transaction -hsystem-mysql -uroot system' | gzip > ./dump/system-mysql-backup.gz

echo "Step 4: 9.4.2. Backing up system-storage"
oc rsync -n "$namespace" $(oc get pods -n "$namespace" -l 'deploymentConfig=system-app' -o json | jq '.items[0].metadata.name' -r):/opt/system/public/system ./dump

echo "Step 5: 9.4.3. Backing up backend-redis"
oc cp -n "$namespace" $(oc get pods -n "$namespace" -l 'deploymentConfig=backend-redis' -o json | jq '.items[0].metadata.name' -r):/var/lib/redis/data/dump.rdb ./dump/backend-redis-dump.rdb

echo "Step 6: 9.4.4. Backing up system-redis" 
oc cp -n "$namespace" $(oc get pods -n "$namespace" -l 'deploymentConfig=system-redis' -o json | jq '.items[0].metadata.name' -r):/var/lib/redis/data/dump.rdb ./dump/system-redis-dump.rdb

echo "Step 7: 9.4.5. Backing up zync-database"
oc rsh -n "$namespace" $(oc get pods -n "$namespace" -l 'deploymentConfig=zync-database' -o json | jq -r '.items[0].metadata.name') bash -c 'pg_dump zync_production' | gzip > ./dump/zync-database-backup.gz
