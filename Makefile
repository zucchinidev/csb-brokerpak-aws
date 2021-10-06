
IAAS=aws
DOCKER_OPTS=--rm -v $(PWD):/brokerpak -w /brokerpak --network=host
CSB=cfplatformeng/csb
USE_GO_CONTAINERS := $(or $(USE_GO_CONTAINERS), 1)

ifeq ($(USE_GO_CONTAINERS), 0)
BUILDER=./cloud-service-broker
else
BUILDER=docker run $(DOCKER_OPTS) $(CSB)
endif

###### Help ###################################################################

.DEFAULT_GOAL = help

.PHONY: help

help: ## list Makefile targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

###### Build ###################################################################

.PHONY: build
build: $(IAAS)-services-*.brokerpak ## build brokerpak

$(IAAS)-services-*.brokerpak: *.yml terraform/*/*/*.tf terraform/*/*/*/*.tf
	$(BUILDER) pak build

###### Run ###################################################################

SECURITY_USER_NAME := $(or $(SECURITY_USER_NAME), aws-broker)
SECURITY_USER_PASSWORD := $(or $(SECURITY_USER_PASSWORD), aws-broker-pw)
#GSB_API_HOSTNAME := $(or $(GSB_API_HOSTNAME), host.docker.internal)
PARALLEL_JOB_COUNT := $(or $(PARALLEL_JOB_COUNT), 2)

.PHONY: run
run: build aws_access_key_id aws_secret_access_key ## start broker with this brokerpak
	docker run $(DOCKER_OPTS) \
	-p 8080:8080 \
	-e SECURITY_USER_NAME \
	-e SECURITY_USER_PASSWORD \
	-e AWS_ACCESS_KEY_ID \
	-e AWS_SECRET_ACCESS_KEY \
	-e "DB_TYPE=sqlite3" \
	-e "DB_PATH=/tmp/csb-db" \
	-e GSB_PROVISION_DEFAULTS \
	$(CSB) serve

###### docs ###################################################################

.PHONY: docs
docs: build brokerpak-user-docs.md ## build docs

brokerpak-user-docs.md: *.yml
	docker run $(DOCKER_OPTS) \
	$(CSB) pak docs /brokerpak/$(shell ls *.brokerpak) > $@

###### examples ###################################################################

.PHONY: examples
examples: ## display available examples
	docker run $(DOCKER_OPTS) \
	-e SECURITY_USER_NAME \
	-e SECURITY_USER_PASSWORD \
	-e USER \
	$(CSB) client examples

###### run-examples ###################################################################

.PHONY: run-examples
run-examples: ## run examples in yml files. Runs examples for all services by default. Set service_name and example_name to run all examples for a specific service or an specific example.
	docker run $(DOCKER_OPTS) \
	-e SECURITY_USER_NAME \
	-e SECURITY_USER_PASSWORD \
	-e USER \
	$(CSB) client run-examples --service-name=$(service_name) --example-name=$(example_name) -j $(PARALLEL_JOB_COUNT)

###### info ###################################################################

.PHONY: info ## show brokerpak info
info: build
	docker run $(DOCKER_OPTS) \
	$(CSB) pak info /brokerpak/$(shell ls *.brokerpak)

###### validate ###################################################################

.PHONY: validate
validate: build ## validate pak syntax
	docker run $(DOCKER_OPTS) \
	$(CSB) pak validate /brokerpak/$(shell ls *.brokerpak)

###### push-broker ###################################################################

# fetching bits for cf push broker
cloud-service-broker:
	wget $(shell curl -sL https://api.github.com/repos/cloudfoundry-incubator/cloud-service-broker/releases/latest | jq -r '.assets[] | select(.name == "cloud-service-broker.linux") | .browser_download_url')
	mv ./cloud-service-broker.linux ./cloud-service-broker
	chmod +x ./cloud-service-broker

local-cloud-service-broker:
	cp ../cloud-service-broker/build/cloud-service-broker.linux ./cloud-service-broker
	chmod +x cloud-service-broker

APP_NAME := $(or $(APP_NAME), cloud-service-broker-aws)
DB_TLS := $(or $(DB_TLS), skip-verify)
GSB_PROVISION_DEFAULTS := $(or $(GSB_PROVISION_DEFAULTS), {"aws_vpc_id": "$(AWS_PAS_VPC_ID)"})

.PHONY: push-broker
push-broker: cloud-service-broker build aws_access_key_id aws_secret_access_key aws_pas_vpc_id ## push the broker with this brokerpak
	MANIFEST=cf-manifest.yml APP_NAME=$(APP_NAME) DB_TLS=$(DB_TLS) GSB_PROVISION_DEFAULTS='$(GSB_PROVISION_DEFAULTS)' ./scripts/push-broker.sh

.PHONY: push-local-broker
push-local-broker: local-cloud-service-broker build aws_access_key_id aws_secret_access_key aws_pas_vpc_id ## push the broker with this brokerpak
	MANIFEST=cf-manifest.yml APP_NAME=$(APP_NAME) DB_TLS=$(DB_TLS) GSB_PROVISION_DEFAULTS='$(GSB_PROVISION_DEFAULTS)' ./scripts/push-broker.sh

.PHONY: collect-released
collect-released:
	mkdir -p ../aws-released
	wget $(shell curl -sL https://api.github.com/repos/cloudfoundry-incubator/cloud-service-broker/releases/latest | jq -r '.assets[] | select(.name == "cloud-service-broker.linux") | .browser_download_url') -P ../aws-released
	mv ./../aws-released/cloud-service-broker.linux ./../aws-released/cloud-service-broker
	chmod +x ./../aws-released/cloud-service-broker
	wget $(shell curl -sL https://api.github.com/repos/cloudfoundry-incubator/csb-brokerpak-aws/releases/latest | jq -r '.assets[0].browser_download_url') -P ../aws-released
	cp cf-manifest.yml ../aws-released

.PHONY: aws_access_key_id
aws_access_key_id:
ifndef AWS_ACCESS_KEY_ID
	$(error variable AWS_ACCESS_KEY_ID not defined)
endif

.PHONY: aws_secret_access_key
aws_secret_access_key:
ifndef AWS_SECRET_ACCESS_KEY
	$(error variable AWS_SECRET_ACCESS_KEY not defined)
endif

.PHONY: aws_pas_vpc_id
aws_pas_vpc_id:
ifndef AWS_PAS_VPC_ID
	$(error variable AWS_PAS_VPC_ID not defined - must be VPC ID for PAS foundation)
endif

###### clean ###################################################################

.PHONY: clean
clean: ## delete build files
	- rm $(IAAS)-services-*.brokerpak
	- rm ./cloud-service-broker
	- rm ./brokerpak-user-docs.md
	- rm -rf ../aws-released