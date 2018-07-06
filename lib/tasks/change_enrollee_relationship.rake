require File.join(Rails.root,"app","data_migrations","change_enrollee_relationship.rb")

# This task changes the relationship of an enrollee on a policy in Glue. 
# RAILS_ENV=production bundle exec rake migrations:change_enrollee_relationship eg_id="123456" hbx_id="1114567" new_relationship="life partner"

namespace :migrations do 
  desc "Change Enrollee Relationship"
  ChangeEnrolleeRelationship.define_task :change_enrollee_relationship => :environment
end