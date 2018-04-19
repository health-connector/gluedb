# Changes an Enrollee's Member ID 
require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeEnrolleeRelationship < MongoidMigrationTask

  def migrate
    policy = Policy.where(eg_id: ENV['eg_id']).first
    (raise "This policy cannot be found." if policy.blank?) unless Rails.env.test?
    enrollee = policy.enrollees.detect{|en| en.m_id == ENV['hbx_id']}
    (raise "This enrollee cannot be found." if enrollee.blank?) unless Rails.env.test? 
    enrollee.update_attributes(:rel_code => ENV['new_relationship'])
    puts "Relationship of enrollee is now #{enrollee.rel_code}" unless Rails.env.test?
  end
  
end