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
oc rollout latest dc/system-sphinx -n "$namespace"
oc rollout status dc/system-sphinx -n "$namespace"

oc rollout latest dc/apicast-production -n "$namespace"
oc rollout status dc/apicast-staging -n "$namespace"

oc rollout latest dc/system-sidekiq
oc rollout status dc/system-sidekiq

oc rollout latest dc/zync
oc rollout status dc/zync

oc rollout latest dc/zync-que
oc rollout status dc/zync-que

oc rsh $(oc get pods -l 'deploymentConfig=system-sidekiq' -o json | jq '.items[0].metadata.name' -r) bash -c 'bundle exec rake zync:resync:domains'
