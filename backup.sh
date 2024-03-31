#!/bin/bash

# Verifica se a pasta .ocp existe
if [ -d "./ocp" ]; then
    # Se existe, apaga a pasta
    rm -rf ./ocp  -rfv  
fi
if [ -d "./dump" ]; then
    # Se existe, apaga a pasta
    rm -rf ./dump  -rfv  
fi


#Config Maps
mkdir ./ocp/configmap/ -p

oc get configmaps system-environment -o json > ./ocp/configmap/system-environment.json
oc get configmaps apicast-environment -o json > ./ocp/configmap/apicast-environment.json

mkdir ./ocp/secrets/ -p
#Secrets
oc get secrets system-smtp -o json > ./ocp/secrets/system-smtp.json
oc get secrets system-seed -o json > ./ocp/secrets/system-seed.json
oc get secrets system-database -o json > ./ocp/secrets/system-database.json
oc get secrets backend-internal-api -o json > ./ocp/secrets/backend-internal-api.json
oc get secrets system-events-hook -o json > ./ocp/secrets/system-events-hook.json
oc get secrets system-app -o json > ./ocp/secrets/system-app.json
oc get secrets system-recaptcha -o json > ./ocp/secrets/system-recaptcha.json
oc get secrets system-redis -o json > ./ocp/secrets/system-redis.json
oc get secrets zync -o json > ./ocp/secrets/zync.json
oc get secrets system-master-apicast -o json > ./ocp/secrets/system-master-apicast.json

mkdir ./dump

echo "Passo 1"
oc rsh $(oc get pods -l 'deploymentConfig=system-mysql' -o json | jq -r '.items[0].metadata.name') bash -c 'export MYSQL_PWD=${MYSQL_ROOT_PASSWORD}; mysqldump --single-transaction -hsystem-mysql -uroot system' | gzip > ./dump/system-mysql-backup.gz

echo "Passo 2"
oc rsync $(oc get pods -l 'deploymentConfig=system-app' -o json | jq '.items[0].metadata.name' -r):/opt/system/public/system ./dump

echo "Passo 3"
oc cp $(oc get pods -l 'deploymentConfig=backend-redis' -o json | jq '.items[0].metadata.name' -r):/var/lib/redis/data/dump.rdb ./dump/backend-redis-dump.rdb

echo "Passo 4"
oc cp $(oc get pods -l 'deploymentConfig=system-redis' -o json | jq '.items[0].metadata.name' -r):/var/lib/redis/data/dump.rdb ./dump/system-redis-dump.rdb

echo "Passo 5"
oc rsh $(oc get pods -l 'deploymentConfig=zync-database' -o json | jq -r '.items[0].metadata.name') bash -c 'pg_dump zync_production' | gzip > ./dump/zync-database-backup.gz



