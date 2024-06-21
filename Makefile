-include .env

##----------------------------------------------------------------------------------------------------------------------
## Defalts & Variables

.DEFAULT_GOAL          := help
APP_TAG                := node
CURRENT_BRANCH         := $(shell [ -d .git ] && git rev-parse --abbrev-ref HEAD)
DC_DEV                 := --project-directory . -f compose/docker-compose.yml
GIT_SHA                := $(shell [ -d .git ] && git rev-parse HEAD)
GITHUB_APP             := node-boilerplate
GITHUB_ORG             := danielmconrad
NOW                    := $(shell date "+%Y-%m-%d")

%:
	@echo "Unknown target '$@'"
	@exit 0

.env:
	@if [ "$${CI}"  = "true" ]; then env | grep -iE '^${WEB_VARS}' | cat > .env; fi
	@if [ "$${CI}" != "true" ]; then [ -f ".env" ] || cp .env.sample .env; fi


##----------------------------------------------------------------------------------------------------------------------
##@ Help

##? This help command. Anything prepended with a double hash will be displayed to the CLI user
help:
	@awk 'BEGIN { FS = "\n"; printf "\nUsage:\n  make [target] VARIABLE=value \033[36m\033[0m\n" } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } /^##\? .*/ { getline x; target=substr(x, 0, index(x, ":")-1); hlptext=substr($$1, index($$1, " ")+1); printf "  \033[36m%-35s\033[0m %s\n", target, hlptext }' $(MAKEFILE_LIST)


##----------------------------------------------------------------------------------------------------------------------
##@ Installation

##? Fully prepares a local development environment
install: dev-destroy
	@echo "\n\nInstallation complete. Run 'make dev' to start the development environment."


##----------------------------------------------------------------------------------------------------------------------
##@ Local Development

##? Runs a development environment
dev: dc-build-dev
	@docker-compose ${DC_DEV} up --remove-orphans

##? Runs a development environment in the background
dev-up: dc-build-dev
	@docker-compose ${DC_DEV} up -d --remove-orphans

##? Downs all possible docker containers
dev-down:
	@docker-compose ${DC_TST} down
	@docker-compose ${DC_DEV} down

##? Stops all possible docker containers
dev-stop:
	@docker-compose ${DC_TST} stop
	@docker-compose ${DC_DEV} stop

##? Destroys all possible docker containers and volumes
dev-destroy:
	@docker ps -a \
		| grep ${GITHUB_APP}- \
		| cut -d' ' -f1 \
		| xargs -I{} sh -c "docker kill {} &> /dev/null; docker rm {}"
	@docker volume rm $(shell docker volume ls -q | grep ${GITHUB_APP}) &> /dev/null || true

## ---------------------

##? Starts an client development environment
dev-client: dc-build-dev-client
	@docker-compose ${DC_DEV} run --rm -p 13000:13000 client

## ---------------------

dc-build-dev:
	@docker-compose ${DC_DEV} build $${CONTAINER}

dc-build-dev-client:
	@docker-compose ${DC_DEV} build client


##----------------------------------------------------------------------------------------------------------------------
##@ Shell & Console

##? Opens a shell into a client (nodejs) container
shell-dev-client: dc-build-dev-client
	@docker-compose ${DC_DEV} run --rm client bash


##----------------------------------------------------------------------------------------------------------------------
##@ Formatting

##? Formats all code
format:
	@make format-client
	@make format-web

##? Formats client code
format-client:
	@docker-compose ${DC_DEV} run --rm client sh -c "yarn format"


##----------------------------------------------------------------------------------------------------------------------
##@ Testing

##? Runs all tests for the codebase
test:
	@make test-client
	@make test-client-format

##? Runs client tests
test-client: dc-build-test-client
	@docker-compose ${DC_TST} run --rm client sh -c "yarn test"

##? Runs client tests in debug mode
test-client-debug: dc-build-test-client
	@echo "\n\nOpen Chrome to begin debugging: chrome://inspect\n\n"
	@docker-compose ${DC_TST} run --rm client sh -c "yarn test:debug $${TEST}"

##? Runs formatting tests for client
test-client-format: dc-build-test-client
	@docker-compose ${DC_TST} run --rm client sh -c "yarn test:format"
