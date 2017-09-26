require File.join(Rails.root,"app","data_migrations","change_hbx_id.rb")

# This rake task merges people in Glue.
# format RAILS_ENV=production bundle exec rake migrations:change_hbx_id database_id='some_mongo_id' person_hbx_id='original_hbx_id' new_hbx_id='new_hbx_id'

namespace :migrations do 
  desc "Change Hbx Id"
  ChangeHbxId.define_task :change_hbx_id => :environment
end