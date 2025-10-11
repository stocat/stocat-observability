SHELL := /bin/sh

# ---- Config ----
HELM        ?= helm
KUBECTL     ?= kubectl
RELEASE     ?= clickstack
NAMESPACE   ?= observability
VALUES      ?= values.yaml
API_KEY     ?=

# Optional kube context (e.g., kind-clickstack)
KUBE_CONTEXT ?= kind-local
KCTX    := $(if $(KUBE_CONTEXT),--kube-context $(KUBE_CONTEXT),)
KCTXCTL := $(if $(KUBE_CONTEXT),--context $(KUBE_CONTEXT),)

# kind settings
KIND        ?= kind
KIND_NAME   ?= clickstack
KIND_CONFIG ?= kind-config.yaml

# ---- Repo & Deps ----
.PHONY: repo deps
repo:
	$(HELM) repo add hyperdx https://hyperdxio.github.io/helm-charts || true
	$(HELM) repo update

deps:
	$(HELM) dependency update .

# ---- Namespace & Secret ----
.PHONY: ns secret
ns:
	$(KUBECTL) $(KCTXCTL) get ns $(NAMESPACE) >/dev/null 2>&1 || $(KUBECTL) $(KCTXCTL) create ns $(NAMESPACE)

secret: ns
	@if [ -z "$(API_KEY)" ]; then \
		echo "[ERROR] Set API_KEY=... when calling make secret"; \
		exit 1; \
	fi
	$(KUBECTL) $(KCTXCTL) -n $(NAMESPACE) create secret generic hyperdx-secret \
	  --from-literal=API_KEY=$(API_KEY) \
	  --dry-run=client -o yaml | $(KUBECTL) $(KCTXCTL) apply -f -

# ---- Install/Upgrade/Uninstall ----
.PHONY: install upgrade uninstall template status
install: repo deps ns
	$(HELM) upgrade -i $(RELEASE) . -n $(NAMESPACE) -f $(VALUES) $(KCTX)

upgrade: deps
	$(HELM) upgrade $(RELEASE) . -n $(NAMESPACE) -f $(VALUES) $(KCTX)

uninstall:
	-$(HELM) uninstall $(RELEASE) -n $(NAMESPACE) $(KCTX)

template:
	$(HELM) template $(RELEASE) . -n $(NAMESPACE) -f $(VALUES) $(KCTX)

status:
	$(HELM) status $(RELEASE) -n $(NAMESPACE) $(KCTX) || true

# ---- Convenience ----
.PHONY: all
all: repo deps secret install

# ---- kind helpers ----
.PHONY: kind-create kind-delete kind-context
kind-create:
	@if [ -f "$(KIND_CONFIG)" ]; then \
		$(KIND) create cluster --name $(KIND_NAME) --config $(KIND_CONFIG); \
	else \
		$(KIND) create cluster --name $(KIND_NAME); \
	fi

kind-delete:
	-$(KIND) delete cluster --name $(KIND_NAME)

# Prints the kube context name for the kind cluster
kind-context:
	@echo kind-$(KIND_NAME)
