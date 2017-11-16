require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeSsn < MongoidMigrationTask

  def migrate
    hbx_id = ENV['hbx_id']
    new_ssn = ENV['new_ssn']
    person = Person.find_for_member_id(hbx_id)
    member = person.members.detect{|member| member.hbx_member_id == hbx_id}
    member.update_attributes!(:ssn => new_ssn)
  end
end