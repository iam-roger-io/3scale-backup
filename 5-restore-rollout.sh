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

echo "deployment/backend-worker"
oc rollout restart deployment/backend-worker -n "$namespace"
oc rollout status deployment/backend-worker -n "$namespace"

echo "deployment/system-app"
oc patch deployment/system-app -n "$namespace" -p '{"spec": {"replicas": 1}}'
oc rollout restart deployment/system-app -n "$namespace"
oc rollout status deployment/system-app -n "$namespace"

echo "deployment/system-searchd"
oc rollout restart deployment/system-searchd -n "$namespace"
oc rollout status deployment/system-searchd -n "$namespace"

echo "deployment/apicast-production"
oc rollout restart deployment/apicast-production -n "$namespace"
oc rollout status deployment/apicast-production -n "$namespace"

echo "deployment/system-sidekiq"
oc rollout restart deployment/system-sidekiq -n "$namespace"
oc rollout status deployment/system-sidekiq -n "$namespace"

echo "deployment/zync"
oc rollout restart deployment/zync -n "$namespace"
oc rollout status deployment/zync -n "$namespace"

echo "deployment/zync-que"
oc rollout restart deployment/zync-que -n "$namespace"
oc rollout status deployment/zync-que -n "$namespace"

# Resync domains
POD=$(oc get pods -l 'deployment=system-sidekiq' -n "$namespace" -o json | jq -r '.items[0].metadata.name')
oc rsh "$POD" bash -c 'bundle exec rake zync:resync:domains'
