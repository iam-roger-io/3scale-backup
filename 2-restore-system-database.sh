#!/bin/bash

echo "passo 1: Copy the MySQL dump to the system-mysql pod:"
#9.5.2. Restoring system-mysql
oc cp ./dump/system-mysql-backup.gz $(oc get pods -l 'deploymentConfig=system-mysql' -o json | jq '.items[0].metadata.name' -r):/var/lib/mysql

echo "passo 2: Decompress the backup file:"
oc rsh $(oc get pods -l 'deploymentConfig=system-mysql' -o json | jq -r '.items[0].metadata.name') bash -c 'gzip -d ${HOME}/system-mysql-backup.gz'

echo "passo 3: Restore the MySQL DB Backup file"
oc rsh $(oc get pods -l 'deploymentConfig=system-mysql' -o json | jq -r '.items[0].metadata.name') bash -c 'export MYSQL_PWD=${MYSQL_ROOT_PASSWORD}; mysql -hsystem-mysql -uroot system < ${HOME}/system-mysql-backup'

#9.5.3. Restoring system-storage
echo "passo 4: Restore the Backup file to system-storage:"
oc rsync ./dump/system/ $(oc get pods -l 'deploymentConfig=system-app' -o json | jq '.items[0].metadata.name' -r):/opt/system/public/system

echo "Fim"