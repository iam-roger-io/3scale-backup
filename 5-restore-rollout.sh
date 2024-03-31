#!/bin/bash
echo "dc/backend-worker"
oc rollout latest dc/backend-worker
oc rollout status dc/backend-worker

echo "dc/system-app"
oc patch dc/system-app -p '{"spec": {"replicas": 1}}'
oc rollout latest dc/system-app
oc rollout status dc/system-app

echo "system-searchd"
oc rollout latest dc/system-searchd
oc rollout status dc/system-searchd

oc rollout latest dc/apicast-production
oc rollout status dc/apicast-staging