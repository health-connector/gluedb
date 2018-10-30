# Changes the Broker NPN
require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeCarrierName < MongoidMigrationTask

 def migrate
   new_name= ENV['new_name']
   carrier = Carrier.where(hbx_carrier_id: ENV['hbx_carrier_id']).first
   if carrier.present?
    carrier.update_attributes!(name: new_name)
    puts "Carrier Name update to #{carrier.name}" unless Rails.env.test?
   else
    puts "Could not find that carrier, please check the hbx_carrier_id"  unless Rails.env.test?
   end
 end
 
end