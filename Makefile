SHELL := /bin/sh

# ---- Config ----
HELM        ?= helm
KUBECTL     ?= kubectl
RELEASE     ?= clickstack
NAMESPACE   ?= observability
VALUES      ?= values.yaml
API_KEY     ?=

# Optional kube context (e.g., kind-clickstack)
KUBE_CONTEXT ?= kind-kind-local
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
.PHONY: ns
ns:
	$(KUBECTL) $(KCTXCTL) get ns $(NAMESPACE) >/dev/null 2>&1 || $(KUBECTL) $(KCTXCTL) create ns $(NAMESPACE)
	$(KUBECTL) $(KCTXCTL) label ns $(NAMESPACE) istio-injection=disabled --overwrite # istio 임시 비활성화 (opamp 이슈)

.PHONY: all clean install upgrade uninstall template status
install:
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
all: repo deps ns install

.PHONY: clean
clean: uninstall


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
