#!/bin/bash

RAILS_ENV=production bundle exec rake db:mongoid:purge
RAILS_ENV=production bundle exec rake db:create
RAILS_ENV=production bundle exec rake db:mongoid:create_indexes
RAILS_ENV=production bundle exec rake ct_demo:load_data
