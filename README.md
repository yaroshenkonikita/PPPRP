# Event Journal Platform

Учебный Kubernetes-проект с REST API, сбором логов на узлах, архивированием и отдельным хранилищем журналов.

## Состав решения

- `event-journal-api` — пользовательское Flask API с эндпоинтами `/`, `/status`, `/log`, `/logs`
- `journal-api-settings` — ConfigMap с параметрами приложения
- `event-journal-probe` — одиночный Pod для первичной проверки
- `event-journal-service` — ClusterIP-сервис для доступа к Deployment
- `node-journal-watcher` — DaemonSet, который читает `app.log` с узла
- `journal-vault` — StatefulSet для периодического копирования логов в архив
- `journal-snapshotter` — CronJob, который забирает логи по HTTP и упаковывает их в `.tar.gz`

## Запуск

```bash
bash deploy.sh
```

## Проверка

```bash
kubectl port-forward svc/event-journal-service 8080:80

curl http://localhost:8080/
curl http://localhost:8080/status
curl -X POST http://localhost:8080/log \
  -H 'Content-Type: application/json' \
  -d '{"message": "test"}'
curl http://localhost:8080/logs

kubectl logs $(kubectl get pods -l app=node-journal-watcher -o jsonpath='{.items[0].metadata.name}')
kubectl get cronjob journal-snapshotter
```

## Структура проекта

```text
app/
  main.py
  requirements.txt
k8s/
  configmap.yaml
  pod.yaml
  deployment.yaml
  service.yaml
  daemonset.yaml
  statefulset.yaml
  cronjob.yaml
Dockerfile
deploy.sh
README.md
```
