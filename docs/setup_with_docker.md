# Installation 
* Install docker on your machine. Follow the offical guideline on docker.com.
* Run `make docker-serve` This will pull the mariadb image and start two containers: one for web and another for the database.  
* Run the following commands to prepare the database. This will create the databased in mariadb and populate them with realistic fake data.  
```shell 
docker compose run app rails db:create db:migrate fake_data
```
