# Changes the phone number on ALL members of a person
require File.join(Rails.root, "lib/mongoid_migration_task")
class ChangePhoneNumber < MongoidMigrationTask

  def migrate
    authority_member_ids = ENV['authority_member_ids'].split(',').uniq
    authority_member_ids.each do |authority_member_id|
      if Person.where(authority_member_id: authority_member_id).size > 1
        puts "There are multiple authority_member_id's for  #{authority_member_id}. Please resolve before changing phone number." unless Rails.env.test?
      elsif Person.where(authority_member_id: authority_member_id).size == 0
        puts "Person #{authority_member_id} not found." unless Rails.env.test?
      else
        person = Person.where(authority_member_id: authority_member_id).first
        phone = person.phones.where(phone_type: ENV['kind']).first
        phone.update_attributes!(phone_number: ENV['phone_number'])
        puts "Successfully changed phone number:#{ENV['phone_number']} of a Person.authority_member_id:#{authority_member_id}." unless Rails.env.test?
      end
    end
  end
end