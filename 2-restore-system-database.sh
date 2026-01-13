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

oc project $namespace

echo "passo 1: Copy the MySQL dump to the system-mysql pod:"
oc cp ./dump/system-mysql-backup.gz $(oc get pods -l 'deployment=system-mysql' -o json | jq -r '.items[0].metadata.name'):/var/lib/mysql

echo "passo 2: Decompress the backup file:"
oc rsh $(oc get pods -l 'deployment=system-mysql' -o json | jq -r '.items[0].metadata.name') bash -c 'gzip -d ${HOME}/system-mysql-backup.gz'

echo "passo 3: Restore the MySQL DB Backup file"
oc rsh $(oc get pods -l 'deployment=system-mysql' -o json | jq -r '.items[0].metadata.name') bash -c 'export MYSQL_PWD=${MYSQL_ROOT_PASSWORD}; mysql -hsystem-mysql -uroot system < ${HOME}/system-mysql-backup'

echo "passo 4: Restore the Backup file to system-storage:"
oc rsync ./dump/system/ $(oc get pods -l 'deployment=system-app' -o json | jq -r '.items[0].metadata.name'):/opt/system/public/system

echo "Fim"
