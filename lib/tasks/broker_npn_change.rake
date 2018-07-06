require File.join(Rails.root,"app","data_migrations","broker_npn_change.rb")

# This rake task changes Broker's NPN. 
# format RAILS_ENV=production bundle exec rake migrations:broker_npn_change old_npn="3255325325" new_npn="123456789"

namespace :migrations do 
  desc "Broker NPN Change"
  BrokerNpNChange.define_task :broker_npn_change => :environment
end