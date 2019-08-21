app_container_name=roman_cart_app
credentials_file=.aws/credentials

define smoke_test
	@echo '--> Check the app is running at $(1)'
	curl --head --url $(1) | head -1 | grep 200 || (echo 'STOP There is a problem, visit $(1)'; exit 1)
	@echo '---> You are ready to go, visit $(1)'
endef

all: build run test smoke_test_dev

help: ## Show this help
		@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

deploy: ## Deploy the app
	docker-compose exec app bundle exec rake deploy

$(credentials_file):
	test -s $(credentials_file) || \
		echo "Step 1: Create a .aws directory at the root of the project and add a \
credentials file with credentials for an AWS user with sufficient \
permissions to deploy to AWS Lambda." && exit

build: $(credentials_file) ## Build the app for local development
	$(info --> Build containers)
	docker-compose build

run: ## Run the app for local development
	docker-compose up -d

test: ## Run the tests
	$(info --> Run the tests)
	docker-compose exec app bundle exec rake
	
smoke_test_dev: ## Ensure that the development environment is working
	$(call smoke_test,http://localhost:3043)

shell: ## Open a shell in the app container
	docker-compose exec app bash

clean: # Clean up
	-docker-compose down
	-docker rmi $(app_container_name)

.PHONY: all help deploy build run test smoke_test_dev shell clean

