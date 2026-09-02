# ⛔ `make down` matters more than `make up`. A cluster you forget about costs about $11 a day.
.PHONY: up demo grafana faults leak heal down leftovers

up:
	eksctl create cluster -f eks/cluster.yaml

demo:
	helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
	helm repo update
	helm install otel-demo open-telemetry/opentelemetry-demo --version 0.41.0 \
	  -n otel-demo --create-namespace --wait --timeout 10m

# Everything is behind one proxy. Grafana, Jaeger and the shop itself.
grafana:
	@echo "Grafana:  http://localhost:8080/grafana/"
	@echo "Jaeger :  http://localhost:8080/jaeger/ui/"
	@echo "Shop   :  http://localhost:8080/"
	kubectl port-forward -n otel-demo svc/frontend-proxy 8080:8080

faults:
	./bin/faults.sh

# Fast enough to watch. The email pod is OOMKilled in about a minute.
leak:
	./bin/fault.sh emailMemoryLeak 10000x

heal:
	./bin/fault.sh emailMemoryLeak off

down:
	eksctl delete cluster -f eks/cluster.yaml --disable-nodegroup-eviction

# Deleting a cluster does not always take everything with it. Run this afterwards.
leftovers:
	./bin/leftovers.sh
