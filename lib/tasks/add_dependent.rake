require File.join(Rails.root,"app","data_migrations","add_dependent.rb")

# This rake task merges people in Glue.
# format RAILS_ENV=production bundle exec rake migrations:add_dependent eg_id="123456" hbx_id="12345" rel_code="self" coverage_start:'10/10/2018' covergae_end:'10/10/2018'

namespace :migrations do 
  desc "Add dependent"
  AddDependent.define_task :add_dependent => :environment
end