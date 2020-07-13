#!/bin/bash

env \
  CXX=clang++ \
  GYPFLAGS=-Dmac_deployment_target=10.9 \
gem install libv8 --version 3.16.14.17

gem install therubyracer -v '0.12.2'
