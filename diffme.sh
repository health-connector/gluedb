#!/bin/bash
# Target directory
TARGET=/target/directory/here

counter=1

for i in $(git diff --name-only development..pdc_models)
do
  printf -v num "%02d" $counter
  git diff --minimal -p development..pdc_models -- "$i" > "patches/${num}.patch"
  counter=$(($counter + 1))
done
