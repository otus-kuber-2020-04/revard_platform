#!/bin/bash

cd ./microservices-demo
git pull
git add *
git status
git commit -m "edit source"
git push -u gitlab master
