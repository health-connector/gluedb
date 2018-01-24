require File.join(Rails.root,"app","data_migrations","change_ssn.rb")

# This rake task merges people in Glue.
# format RAILS_ENV=production bundle exec rake migrations:change_ssn hbx_id='hbx_id of the person' new_ssn='the ssn to change to'

namespace :migrations do 
  desc "Change SSN"
  ChangeSsn.define_task :change_ssn => :environment
end