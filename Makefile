# Convenience targets for the catalog + scaffold demo.
# Written for macOS/BSD userland - no GNU-only flags.

SHELL := /bin/bash

# Prefer OpenTofu, fall back to Terraform. Terragrunt's own default is `tofu`.
TG_TF_PATH ?= $(shell command -v tofu || command -v terraform)
export TG_TF_PATH

.DEFAULT_GOAL := help

.PHONY: help
help:
	@echo "make check     verify terragrunt >= 1.1 and an engine are installed"
	@echo "make catalog   open the catalog TUI"
	@echo "make list      list catalog components without the TUI"
	@echo "make dev       apply the committed reference environment in live/dev"
	@echo "make destroy   destroy everything, then reset"
	@echo "make reset     delete generated files so the demo can be run again"

.PHONY: check
check:
	@command -v terragrunt >/dev/null 2>&1 || { echo "terragrunt not found on PATH"; exit 1; }
	@ver=$$(terragrunt --version | awk '{print $$3}'); \
	 major=$$(echo "$$ver" | cut -d. -f1); \
	 minor=$$(echo "$$ver" | cut -d. -f2); \
	 if [ "$$major" -lt 1 ] || { [ "$$major" -eq 1 ] && [ "$$minor" -lt 1 ]; }; then \
	   echo "terragrunt $$ver is too old - this demo needs >= 1.1.0"; \
	   echo "the interactive scaffold form, component tabs and unit/stack scaffolding are all 1.1+"; \
	   exit 1; \
	 fi; \
	 echo "terragrunt  $$ver"
	@if [ -z "$(TG_TF_PATH)" ]; then echo "neither tofu nor terraform found on PATH"; exit 1; fi
	@echo "engine      $$($(TG_TF_PATH) version | head -1)"
	@echo "TG_TF_PATH  $(TG_TF_PATH)"
	@echo "ok - no cloud credentials needed for any of this"

.PHONY: catalog
catalog:
	@terragrunt catalog

.PHONY: list
list:
	@terragrunt catalog --format=jsonl --experiment=catalog-format 2>/dev/null \
	 | jq -r '"\(.kind)\t\(.title)\t\(.dir)"' | sort | column -t -s "$$(printf '\t')"

.PHONY: dev
dev:
	@terragrunt run --all apply --working-dir live/dev

.PHONY: destroy
destroy:
	-@if [ -f live/dev/network/terragrunt.hcl ]; then \
	   terragrunt run --all destroy --working-dir live/dev --non-interactive; \
	 fi
	-@for d in live/*/; do \
	   if [ -f "$$d/terragrunt.stack.hcl" ]; then \
	     terragrunt stack run destroy --working-dir "$$d" --non-interactive; \
	   fi; \
	 done
	@$(MAKE) --no-print-directory reset

# Removes everything the demo generates, so it can be run start to finish again.
.PHONY: reset
reset:
	@rm -rf .terragrunt-state
	@find . -type d -name '.terragrunt-cache' -prune -print0 | xargs -0 rm -rf
	@find live -type d -name '.terragrunt-stack' -prune -print0 | xargs -0 rm -rf
	@find . -type d -name '.terraform' -prune -print0 | xargs -0 rm -rf
	@find modules -name '.terraform.lock.hcl' -print0 | xargs -0 rm -f
	@find live -mindepth 1 -maxdepth 1 -type d ! -name dev ! -name prod ! -name preview -print0 | xargs -0 rm -rf
	@find live/prod -mindepth 1 -maxdepth 1 ! -name .gitkeep -print0 | xargs -0 rm -rf
	@rm -f live/preview/terragrunt.values.hcl
	@echo "reset - generated files removed, live/dev, live/prod and live/preview left as committed"
