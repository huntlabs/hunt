#!/bin/bash

git init
git remote add origin https://github.com/nodejs/http-parser.git
git fetch
git branch master origin/master
git checkout master -f
make package