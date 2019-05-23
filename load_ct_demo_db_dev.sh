#!/bin/bash

bundle exec rake db:mongoid:purge
bundle exec rake db:create
bundle exec rake db:mongoid:create_indexes
bundle exec rake ct_demo:load_data
