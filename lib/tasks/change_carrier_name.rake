require File.join(Rails.root,"app","data_migrations","change_carrier_name.rb")

# This rake task changes Broker's NPN. 
# format RAILS_ENV=production bundle exec rake migrations:change_carrier_name hbx_carrier_id="12345" new_name="This One Carrier"

namespace :migrations do 
  desc "Change Carrier name"
  ChangeCarrierName.define_task :change_carrier_name => :environment
end