#!/bin/bash

docker run -d --name centos7 centos:7
docker run -d --name ubuntu ubuntu:latest


ansible-playbook -i ./inventory/prod.yml site.yml


docker stop centos7 ubuntu
docker rm centos7 ubuntu

