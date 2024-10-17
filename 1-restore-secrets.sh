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

#NOTA: Antes de instalar o API Manager

echo "9.4.6.1. OpenShift secrets"
oc apply -f ./ocp/secrets/system-smtp.json -n "$namespace"
oc apply -f ./ocp/secrets/system-seed.json -n "$namespace"
oc apply -f ./ocp/secrets/system-database.json -n "$namespace"
oc apply -f ./ocp/secrets/backend-internal-api.json -n "$namespace"
oc apply -f ./ocp/secrets/system-events-hook.json -n "$namespace"
oc apply -f ./ocp/secrets/system-app.json -n "$namespace"
oc apply -f ./ocp/secrets/system-recaptcha.json -n "$namespace"
oc apply -f ./ocp/secrets/system-redis.json -n "$namespace"
oc apply -f ./ocp/secrets/zync.json -n "$namespace"
oc apply -f ./ocp/secrets/system-master-apicast.json -n "$namespace"

echo "9.4.6.2 ConfigMaps"
oc apply -f ./ocp/configmap/apicast-environment.json -n "$namespace"
oc apply -f ./ocp/configmap/system-environment.json -n "$namespace"
