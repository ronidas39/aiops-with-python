# ⛔ `make down` matters more than `make up`. A cluster you forget about costs about $11 a day.
.PHONY: up demo grafana faults leak slowleak heal down leftovers budget metrics cleanlogs limits watch why logs

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

# ⛔ EVERY LONG COMMAND LIVES HERE NOW, AND THAT IS THE POINT. Three recording takes were lost
# because a long command wrapped on the page and the wrap arrived in the shell as a real line
# break. A target name is one word. It cannot wrap.

# Put a $20 monthly budget on the account before you spend anything.
budget:
	aws budgets create-budget --account-id "$$(aws sts get-caller-identity --query Account --output text)" --budget '{"BudgetName":"aiops-course","BudgetLimit":{"Amount":"20","Unit":"USD"},"TimeUnit":"MONTHLY","BudgetType":"COST"}'

# Only needed if `kubectl top` says "Metrics API not available", on eksctl older than 0.201.
metrics:
	kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# What the email service is allowed to use.
limits:
	kubectl describe deploy email -n otel-demo | grep -A3 Limits:

# The slow version of the leak, sampled to a file. Leave it running for an hour.
slowleak:
	./bin/fault.sh emailMemoryLeak 100x
	@echo "sampling to leak.tsv every 25s. control C to stop."
	@while true; do kubectl top pod -n otel-demo -l app.kubernetes.io/component=email --no-headers | awk -v t="$$(date +%s)" '{print t, $$3}'; sleep 25; done | tee leak.tsv

# The one leftover that survives `make down` and keeps billing.
cleanlogs:
	aws logs delete-log-group --region us-east-1 --log-group-name /aws/eks/aiops-lab/cluster

# ⛔ THESE THREE EXIST BECAUSE THE LONG FORMS DO NOT FIT ON A PRINTED PAGE, and a wrapped
# command reaching the shell as two lines is what cost three recording takes.

# Watch ONLY the email pod. Without the label filter you are watching all thirty and the one
# death you care about scrolls past inside the noise.
watch:
	kubectl get pod -n otel-demo -l app.kubernetes.io/component=email -w

# The cluster's own account of why the last container stopped. This is the proof, in
# Kubernetes' words, rather than an exit code you have to trust.
why:
	kubectl describe pod -n otel-demo -l app.kubernetes.io/component=email | grep -A4 "Last State"

# What the pod printed before it was killed. An out of memory kill leaves no error, so the
# last line is an ordinary one and then nothing. That absence is the lesson.
logs:
	kubectl logs deploy/email -n otel-demo --previous --tail=15
