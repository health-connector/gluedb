# Merges duplicate people
require File.join(Rails.root, "lib/mongoid_migration_task")

class MergeDuplicatePeople < MongoidMigrationTask

  def merge_addresses(keep_hbx_id,remove_hbx_id)
    person_to_keep = Person.find_for_member_id(keep_hbx_id)
    person_to_remove = Person.find_for_member_id(remove_hbx_id)
    person_to_remove.addresses.each do |address|
      person_to_keep.merge_address(address)
    end
  end

  def merge_phones(keep_hbx_id,remove_hbx_id)
    person_to_keep = Person.find_for_member_id(keep_hbx_id)
    person_to_remove = Person.find_for_member_id(remove_hbx_id)
    person_to_remove.phones.each do |phone|
      person_to_keep.merge_phone(phone)
    end
  end

  def merge_emails(keep_hbx_id,remove_hbx_id)
    person_to_keep = Person.find_for_member_id(keep_hbx_id)
    person_to_remove = Person.find_for_member_id(remove_hbx_id)
    person_to_remove.emails.each do |email|
      person_to_keep.merge_email(email)
    end
  end

  def move_members(keep_hbx_id,remove_hbx_id)
    person_to_keep = Person.find_for_member_id(keep_hbx_id)
    person_to_remove = Person.find_for_member_id(remove_hbx_id)
    # reps = person_to_remove.members.size
    # reps.times do 
    #   person_to_keep.members << person_to_remove.members.slice!(0)
    # end
    person_to_remove.members.each do |member|
      member_clone = member.clone
      person_to_keep.members << member_clone
      member_clone.save
    end
    person_to_remove.members.delete
  end

  def unset_authority_member_id(keep_hbx_id,remove_hbx_id)
    person_to_keep = Person.find_for_member_id(keep_hbx_id)
    person_to_remove = Person.find_for_member_id(remove_hbx_id)
    person_to_remove.unset(:authority_member_id)
  end

  def migrate
    move_members(ENV['person_to_keep'],ENV['person_to_remove'])
    unset_authority_member_id(ENV['person_to_keep'],ENV['person_to_remove'])
    merge_addresses(ENV['person_to_keep'],ENV['person_to_remove'])
    merge_phones(ENV['person_to_keep'],ENV['person_to_remove'])
    merge_emails(ENV['person_to_keep'],ENV['person_to_remove'])
  end
end