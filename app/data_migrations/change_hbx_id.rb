require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeHbxId < MongoidMigrationTask

  def change_authority_member_id(person,new_hbx_id)
    person.authority_member_id=new_hbx_id
    person.save!
  end

  def change_member_id(member,new_hbx_id)
    member.update_member_hbx_id(new_hbx_id)
  end

  def migrate
    hbx_id = ENV['person_hbx_id']
    new_hbx_id = ENV['new_hbx_id']
    database_id = ENV['database_id']
    person = Person.find(database_id)
    if person.nil?
      puts "No person was found by the given hbx_id: #{hbx_id}" unless Rails.env.test?
    else
      member = person.members.detect{|member| member.hbx_member_id == hbx_id}
      change_member_id(member,new_hbx_id)
      if person.authority_member_id == hbx_id
        change_authority_member_id(person,new_hbx_id)
        puts "Changed authority member ID and member ID from #{hbx_id} to #{new_hbx_id}." unless Rails.env.test?
      else
        puts "Changed member id from #{hbx_id} to #{new_hbx_id}." unless Rails.env.test?
      end
    end
  end
end