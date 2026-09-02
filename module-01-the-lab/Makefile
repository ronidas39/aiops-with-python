# ⛔ `make down` matters more than `make up`. A cluster you forget about costs about $11 a day.
.PHONY: up demo down
up:
	eksctl create cluster -f eks/cluster.yaml
demo:
	helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
	helm install otel-demo open-telemetry/opentelemetry-demo --version 0.41.0 \
	  -n otel-demo --create-namespace --wait --timeout 10m
down:
	eksctl delete cluster -f eks/cluster.yaml --disable-nodegroup-eviction
