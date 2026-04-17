.PHONY: help run-api run-apihost run-ui build build-api rebuild clean clean-all test test-unit migrate migrate-run migrate-list publish-api publish-iis nswag lint install info add-tools

SHELL := pwsh
PS_SCRIPT := powershell.exe -ExecutionPolicy Bypass -File ./make.ps1

help:
	@$(PS_SCRIPT) help

run-api:
	@$(PS_SCRIPT) run-api

run-apihost:
	@$(PS_SCRIPT) run-apihost

run-ui:
	@$(PS_SCRIPT) run-ui

build:
	@$(PS_SCRIPT) build

build-api:
	@$(PS_SCRIPT) build-api

rebuild:
	@$(PS_SCRIPT) rebuild

clean:
	@$(PS_SCRIPT) clean

clean-all:
	@$(PS_SCRIPT) clean-all

test:
	@$(PS_SCRIPT) test

test-unit:
	@$(PS_SCRIPT) test-unit

migrate:
	@$(PS_SCRIPT) migrate $(filter-out $@,$(MAKECMDGOALS))

migrate-run:
	@$(PS_SCRIPT) migrate-run

migrate-list:
	@$(PS_SCRIPT) migrate-list

publish-api:
	@$(PS_SCRIPT) publish-api

publish-iis:
	@$(PS_SCRIPT) publish-iis

nswag:
	@$(PS_SCRIPT) nswag

lint:
	@cd clients/admin && pnpm lint

install:
	@$(PS_SCRIPT) install

info:
	@$(PS_SCRIPT) info

add-tools:
	@$(PS_SCRIPT) add-tools