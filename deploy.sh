#!/bin/bash
set -e

echo "=== Deploying the event journal platform ==="

echo ""
echo "[1/8] Building Docker image event-journal-api..."
if command -v minikube >/dev/null 2>&1 && minikube status >/dev/null 2>&1; then
    echo "Minikube detected, switching to its Docker daemon..."
    eval "$(minikube docker-env)"
fi
docker build -t event-journal-api:latest .

echo ""
echo "[2/8] Applying ConfigMap..."
kubectl apply -f k8s/configmap.yaml

echo ""
echo "[3/8] Creating bootstrap Pod..."
kubectl apply -f k8s/pod.yaml

echo ""
echo "[4/8] Creating Deployment..."
kubectl apply -f k8s/deployment.yaml

echo ""
echo "[5/8] Creating Service..."
kubectl apply -f k8s/service.yaml

echo ""
echo "[6/8] Creating DaemonSet..."
kubectl apply -f k8s/daemonset.yaml

echo ""
echo "[7/8] Creating StatefulSet..."
kubectl apply -f k8s/statefulset.yaml

echo ""
echo "[8/8] Creating CronJob..."
kubectl apply -f k8s/cronjob.yaml

echo ""
echo "=== Waiting for key components ==="

kubectl wait --for=condition=Ready pod/event-journal-probe --timeout=120s
kubectl rollout status deployment/event-journal-api --timeout=120s
kubectl rollout status daemonset/node-journal-watcher --timeout=120s
kubectl rollout status statefulset/journal-vault --timeout=120s

echo ""
echo "=== Deployment finished ==="
echo ""
kubectl get pods
echo ""
kubectl get svc
echo ""
kubectl get cronjob
echo ""
echo "--- Verification ---"
echo "1. kubectl port-forward svc/event-journal-service 8080:80"
echo "2. curl http://localhost:8080/"
echo "3. curl http://localhost:8080/status"
echo "4. curl -X POST http://localhost:8080/log -H 'Content-Type: application/json' -d '{\"message\": \"test\"}'"
echo "5. curl http://localhost:8080/logs"
echo "6. kubectl logs \$(kubectl get pods -l app=node-journal-watcher -o jsonpath='{.items[0].metadata.name}')"
