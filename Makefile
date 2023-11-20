.PHONY: build run stop cluster

build:
	docker build -t hadoop .

run:
	docker exec -it hadoop_master1_1 bash

stop:
	docker-compose down

cluster:
	docker-compose up -d
