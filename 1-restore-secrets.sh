#!/bin/bash

#NOTA: Antes de instalar o API Manager

echo "9.4.6.1. OpenShift secrets"
oc apply -f ./ocp/secrets/system-smtp.json
oc apply -f ./ocp/secrets/system-seed.json
oc apply -f ./ocp/secrets/system-database.json
oc apply -f ./ocp/secrets/backend-internal-api.json
oc apply -f ./ocp/secrets/system-events-hook.json
oc apply -f ./ocp/secrets/system-app.json
oc apply -f ./ocp/secrets/system-recaptcha.json
oc apply -f ./ocp/secrets/system-redis.json
oc apply -f ./ocp/secrets/zync.json
oc apply -f ./ocp/secrets/system-master-apicast.json

echo "9.4.6.2 ConfigMaps"
oc apply -f ./ocp/configmap/apicast-environment.json
oc apply -f ./ocp/configmap/system-environment.json