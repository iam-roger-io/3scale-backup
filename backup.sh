#!/bin/bash

echo "########################################################################"
echo "## B A C K U P   F O R   3 S C A L E"
echo "## Starting backup of 3scale API Manager:"
echo "## Script for version 2.15"
echo "Reference documentation: https://docs.redhat.com/en/documentation/red_hat_3scale_api_management/2.15/html/operating_red_hat_3scale_api_management/threescale-backup-restore"
echo "########################################################################"

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

if [ -d "./ocp" ]; then rm -rf ./ocp -rf; fi
if [ -d "./dump" ]; then rm -rf ./dump -rf; fi

echo "## 9.4.6: Backing up OpenShift secrets and ConfigMaps"
echo "Step 1: 9.4.6.1. OpenShift secrets "
mkdir -p ./ocp/secrets/

oc get secrets system-smtp -n "$namespace" -o yaml | yq eval 'del(.metadata.namespace, .metadata.creationTimestamp, .metadata.resourceVersion, .metadata.uid, .metadata.namespace)' - > ./ocp/secrets/system-smtp.yaml
oc get secrets system-seed -n "$namespace" -o yaml | yq eval 'del(.metadata.namespace, .metadata.creationTimestamp, .metadata.resourceVersion, .metadata.uid, .metadata.namespace)' - >  ./ocp/secrets/system-seed.yaml
oc get secrets system-database -n "$namespace" -o yaml | yq eval 'del(.metadata.namespace, .metadata.creationTimestamp, .metadata.resourceVersion, .metadata.uid, .metadata.namespace)' - >   ./ocp/secrets/system-database.yaml
oc get secrets backend-internal-api -n "$namespace" -o yaml | yq eval 'del(.metadata.namespace, .metadata.creationTimestamp, .metadata.resourceVersion, .metadata.uid, .metadata.namespace)' - > ./ocp/secrets/backend-internal-api.yaml
oc get secrets system-events-hook -n "$namespace" -o yaml | yq eval 'del(.metadata.namespace, .metadata.creationTimestamp, .metadata.resourceVersion, .metadata.uid, .metadata.namespace)' - >  ./ocp/secrets/system-events-hook.yaml
oc get secrets system-app -n "$namespace" -o yaml | yq eval 'del(.metadata.namespace, .metadata.creationTimestamp, .metadata.resourceVersion, .metadata.uid, .metadata.namespace)' - >  ./ocp/secrets/system-app.yaml
oc get secrets system-recaptcha -n "$namespace" -o yaml | yq eval 'del(.metadata.namespace, .metadata.creationTimestamp, .metadata.resourceVersion, .metadata.uid, .metadata.namespace)' - >  ./ocp/secrets/system-recaptcha.yaml
oc get secrets system-redis -n "$namespace" -o yaml | yq eval 'del(.metadata.namespace, .metadata.creationTimestamp, .metadata.resourceVersion, .metadata.uid, .metadata.namespace)' - >  ./ocp/secrets/system-redis.yaml
oc get secrets zync -n "$namespace" -o yaml | yq eval 'del(.metadata.namespace, .metadata.creationTimestamp, .metadata.resourceVersion, .metadata.uid, .metadata.namespace)' - >  ./ocp/secrets/zync.yaml
oc get secrets system-master-apicast -n "$namespace" -o yaml | yq eval 'del(.metadata.namespace, .metadata.creationTimestamp, .metadata.resourceVersion, .metadata.uid, .metadata.namespace)' - >  ./ocp/secrets/system-master-apicast.yaml

mkdir -p ./ocp/configmap/
echo "Step 2: 9.4.6.2. ConfigMaps"
oc get configmaps system-environment -n "$namespace" -o yaml | yq eval 'del(.metadata.namespace, .metadata.creationTimestamp, .metadata.resourceVersion, .metadata.uid, .metadata.ownerReferences, .metadata.namespace)' - >  ./ocp/configmap/system-environment.yaml
oc get configmaps apicast-environment -n "$namespace" -o yaml | yq eval 'del(.metadata.namespace, .metadata.creationTimestamp, .metadata.resourceVersion, .metadata.uid, .metadata.ownerReferences, .metadata.namespace)' - >  ./ocp/configmap/apicast-environment.yaml

echo " "
echo "## 9.4: Backing up system databases"
mkdir ./dump

echo "Step 3: 9.4.1. Backing up system-mysql"
oc rsh -n "$namespace" $(oc get pods -n "$namespace" -l 'deployment=system-mysql' -o json | jq -r '.items[0].metadata.name') bash -c 'export MYSQL_PWD=${MYSQL_ROOT_PASSWORD}; mysqldump --single-transaction -hsystem-mysql -uroot system' | gzip > ./dump/system-mysql-backup.gz

echo "Step 4: 9.4.2. Backing up system-storage"
oc rsync -n "$namespace" $(oc get pods -n "$namespace" -l 'deployment=system-app' -o json | jq '.items[0].metadata.name' -r):/opt/system/public/system ./dump

echo "Step 5: 9.4.3. Backing up backend-redis"
oc cp -n "$namespace" $(oc get pods -n "$namespace" -l 'deployment=backend-redis' -o json | jq '.items[0].metadata.name' -r):/var/lib/redis/data/dump.rdb ./dump/backend-redis-dump.rdb

echo "Step 6: 9.4.4. Backing up system-redis"
oc cp -n "$namespace" $(oc get pods -n "$namespace" -l 'deployment=system-redis' -o json | jq '.items[0].metadata.name' -r):/var/lib/redis/data/dump.rdb ./dump/system-redis-dump.rdb

echo "Step 7: 9.4.5. Backing up zync-database"
oc rsh -n "$namespace" $(oc get pods -n "$namespace" -l 'deployment=zync-database' -o json | jq -r '.items[0].metadata.name') bash -c 'pg_dump zync_production' | gzip > ./dump/zync-database-backup.gz

echo "Step 8: Backing up APIManager CRD"
TENANT=$(oc get apimanager -A -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | head -n1)

if [ -z "$TENANT" ]; then
    echo "❌ Nenhum APIManager encontrado!"
    exit 1
fi

echo "📌 APIManager  encontrado: $TENANT"

# agora precisamos descobrir a namespace real desse tenant
APINS=$(oc get apimanager -A -o jsonpath="{range .items[?(@.metadata.name=='$TENANT')]}{.metadata.namespace}{'\n'}{end}" | head -n1)

oc get apimanager -n "$APINS" "$TENANT" -o yaml > ./ocp/apimanager-crd.yaml

yq eval 'del(.metadata.creationTimestamp, .metadata.generation, .metadata.namespace, .metadata.resourceVersion, .metadata.uid, .status)' -i "./ocp/apimanager-crd.yaml"

#Reavaliar
#./backup-tenants-crd.sh -n "$namespace"
