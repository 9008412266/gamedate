# ============================================================
# Playraze — Local Dev Commands
# Usage: make <target>
# ============================================================

GHCR_USER  := 9008412266
NAMESPACE  := playraze-dev
IMAGE_TAG  := dev-latest

# ── Docker Compose (easiest) ─────────────────────────────────

login:                        ## Login to GHCR (run once)
	@echo "Enter your GitHub Personal Access Token (needs read:packages scope):"
	@read PAT; echo $$PAT | docker login ghcr.io -u $(GHCR_USER) --password-stdin

up:                           ## Start all services
	docker-compose up -d
	@echo "\n✅ Services starting..."
	@echo "   API Gateway:  http://localhost:8080"
	@echo "   Auth:         http://localhost:8081/actuator/health"
	@echo "   Flutter Web:  https://$(GHCR_USER).github.io/gamedate/dev/"

down:                         ## Stop all services
	docker-compose down

restart:                      ## Restart a service: make restart svc=auth-service
	docker-compose restart $(svc)

pull:                         ## Pull latest images from GHCR
	docker-compose pull

logs:                         ## Tail all logs
	docker-compose logs -f

logs-svc:                     ## Tail one service: make logs-svc svc=auth-service
	docker-compose logs -f $(svc)

ps:                           ## Show running containers + health
	docker-compose ps

health:                       ## Check all service health endpoints
	@for port in 8080 8081 8082 8083 8084 8085 8086; do \
		printf "Port $$port: "; \
		curl -sf http://localhost:$$port/actuator/health | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status','?'))" 2>/dev/null || echo "not responding"; \
	done

# ── Kubernetes (k3d) ─────────────────────────────────────────

k3d-create:                   ## Create local k3d cluster
	k3d cluster create playraze \
		--port "8080:80@loadbalancer" \
		--port "8443:443@loadbalancer" \
		--agents 2
	kubectl config use-context k3d-playraze
	@echo "✅ k3d cluster created"

k3d-delete:                   ## Delete local k3d cluster
	k3d cluster delete playraze

k3d-import:                   ## Import GHCR images into k3d cluster
	@for svc in api-gateway auth-service user-service game-service chat-service wallet-service notification-service; do \
		echo "Importing $$svc..."; \
		k3d image import ghcr.io/$(GHCR_USER)/playraze-$$svc:$(IMAGE_TAG) -c playraze; \
	done

k8s-apply:                    ## Apply all k8s manifests
	kubectl apply -f k8s/

k8s-delete:                   ## Delete all k8s resources
	kubectl delete -f k8s/

k8s-pods:                     ## Show all pods + status
	kubectl get pods -n $(NAMESPACE) -o wide

k8s-logs:                     ## Tail pod logs: make k8s-logs pod=auth-service
	kubectl logs -f -n $(NAMESPACE) -l app=$(pod) --tail=100

k8s-logs-all:                 ## Tail all pod logs
	kubectl logs -f -n $(NAMESPACE) --all-containers=true --prefix=true --tail=50 \
		-l 'app in (api-gateway,auth-service,user-service,game-service,chat-service,wallet-service,notification-service)'

k8s-describe:                 ## Describe a pod: make k8s-describe pod=auth-service
	kubectl describe pod -n $(NAMESPACE) -l app=$(pod)

k8s-events:                   ## Show recent k8s events (errors etc.)
	kubectl get events -n $(NAMESPACE) --sort-by='.lastTimestamp' | tail -20

k8s-port-forward:             ## Port-forward api-gateway to localhost:8080
	kubectl port-forward -n $(NAMESPACE) svc/api-gateway 8080:8080

k8s-shell:                    ## Shell into a pod: make k8s-shell pod=auth-service
	kubectl exec -it -n $(NAMESPACE) \
		$$(kubectl get pod -n $(NAMESPACE) -l app=$(pod) -o jsonpath='{.items[0].metadata.name}') \
		-- /bin/sh

k8s-restart:                  ## Rolling restart: make k8s-restart svc=auth-service
	kubectl rollout restart deployment/$(svc) -n $(NAMESPACE)

k8s-status:                   ## Show deployments + pods + services
	@echo "\n=== Deployments ==="; kubectl get deploy -n $(NAMESPACE)
	@echo "\n=== Pods ===";        kubectl get pods  -n $(NAMESPACE)
	@echo "\n=== Services ===";    kubectl get svc   -n $(NAMESPACE)

.PHONY: login up down restart pull logs logs-svc ps health \
        k3d-create k3d-delete k3d-import \
        k8s-apply k8s-delete k8s-pods k8s-logs k8s-logs-all \
        k8s-describe k8s-events k8s-port-forward k8s-shell k8s-restart k8s-status
