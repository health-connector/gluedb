require File.join(Rails.root,"app","data_migrations","change_enrollee_member_id.rb")

# This task changes the hbx member ID of an enrollee on a policy in Glue. 
# RAILS_ENV=production bundle exec rake migrations:change_enrollee_member_id eg_id="123456" old_hbx_id="1114567" new_hbx_id="1111567"

namespace :migrations do 
  desc "Change Enrollee Member ID"
  ChangeEnrolleeMemberId.define_task :change_enrollee_member_id => :environment
end