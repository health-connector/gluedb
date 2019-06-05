require File.join(Rails.root,"app","data_migrations","change_phone_number.rb")

# This rake tasks changes phone number from all members of a person in Glue. 
# format RAILS_ENV=production bundle exec rake migrations:change_phone_number authority_member_ids='123456,123444,123456' kind='work' phone_number='1234567890'

namespace :migrations do 
  desc "Change Phone Number Of A Person"
  ChangePhoneNumber.define_task :change_phone_number => :environment
end