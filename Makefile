.PHONY: lint test

test:
	bundle exec rspec
	brakeman -q 

lint: 
	bundle exec standardrb --fix-unsafely

docker-serve:
	docker compose up --build

all: lint test
