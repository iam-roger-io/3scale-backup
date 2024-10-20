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
oc apply -f ./ocp/secrets/system-smtp.yaml -n "$namespace"
oc apply -f ./ocp/secrets/system-seed.yaml -n "$namespace"
oc apply -f ./ocp/secrets/system-database.yaml -n "$namespace"
oc apply -f ./ocp/secrets/backend-internal-api.yaml -n "$namespace"
oc apply -f ./ocp/secrets/system-events-hook.yaml -n "$namespace"
oc apply -f ./ocp/secrets/system-app.yaml -n "$namespace"
oc apply -f ./ocp/secrets/system-recaptcha.yaml -n "$namespace"
oc apply -f ./ocp/secrets/system-redis.yaml -n "$namespace"
oc apply -f ./ocp/secrets/zync.yaml -n "$namespace"
oc apply -f ./ocp/secrets/system-master-apicast.yaml -n "$namespace"

echo "9.4.6.2 ConfigMaps"
oc apply -f ./ocp/configmap/apicast-environment.yaml -n "$namespace"
oc apply -f ./ocp/configmap/system-environment.yaml -n "$namespace"
