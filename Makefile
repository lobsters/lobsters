.PHONY: lint test

test:
	bundle exec rspec
	brakeman -q 

lint: 
	bundle exec standardrb --fix-unsafely

docker-serve:
	export RUBY_VERSION=`cat .ruby-version`
	docker compose up --build

all: lint test
