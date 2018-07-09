# Changes the Broker NPN
require File.join(Rails.root, "lib/mongoid_migration_task")

class BrokerNpNChange < MongoidMigrationTask
 def migrate
   old_npn= ENV['old_npn']
   new_npn= ENV['new_npn']
   broker_old_npn = Broker.find_by_npn(old_npn)
   broker_new_npn = Broker.find_by_npn(new_npn)
   if broker_new_npn.present?
     puts "Broker with new NPN #{new_npn} already exists. Please check the given NPN" unless Rails.env.test?
   else
     broker_old_npn.update_attributes(:npn => new_npn)
     puts "Broker NPN has been succesfully updated!" unless Rails.env.test?
   end
 end
end