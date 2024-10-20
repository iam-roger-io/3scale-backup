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

echo "dc/backend-worker"
oc rollout latest dc/backend-worker -n "$namespace"
oc rollout status dc/backend-worker -n "$namespace"

echo "dc/system-app"
oc patch dc/system-app -n "$namespace" -p '{"spec": {"replicas": 1}}'
oc rollout latest dc/system-app -n "$namespace"
oc rollout status dc/system-app -n "$namespace"

echo "dc/system-searchd"
oc rollout latest dc/system-searchd  -n "$namespace"
oc rollout status dc/system-searchd  -n "$namespace"


echo "dc/apicast-production"
oc rollout latest dc/apicast-production -n "$namespace"
oc rollout status dc/apicast-staging -n "$namespace"

echo "dc/system-sidekiq"
oc rollout latest dc/system-sidekiq -n "$namespace"
oc rollout status dc/system-sidekiq -n "$namespace"

echo "dc/zync"
oc rollout latest dc/zync -n "$namespace"
oc rollout status dc/zync -n "$namespace"

echo "dc/zync-que"
oc rollout latest dc/zync-que -n "$namespace"
oc rollout status dc/zync-que -n "$namespace"

oc rsh $(oc get pods -l 'deploymentConfig=system-sidekiq' -o json | jq '.items[0].metadata.name' -r) bash -c 'bundle exec rake zync:resync:domains'
