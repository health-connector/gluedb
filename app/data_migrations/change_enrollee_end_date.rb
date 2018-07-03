require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeEnrolleeEndDate < MongoidMigrationTask
 def migrate
   policy = Policy.where(eg_id: ENV['eg_id']).first
   m_id = ENV['m_id']
   end_on = Date.strptime(ENV['new_end_date'].to_s, "%m/%d/%Y")
   if policy.blank?
     puts "No hbx_enrollment was found with the given hbx_id" unless Rails.env.test?
   else
     enrollee=policy.enrollees.where(m_id: m_id).first
     enrollee.update_attributes!(coverage_end: end_on)
      puts "enrollee coverage end modified...!" unless Rails.env.test?
   end
 end
end