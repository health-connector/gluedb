# Merges duplicate employers
require File.join(Rails.root, "lib/mongoid_migration_task")

class MergeDuplicateEmployers < MongoidMigrationTask

  def merge_addresses(employer_to_keep,employer_to_remove)
    employer_to_remove.addresses.each do |address|
      employer_to_keep.merge_address(address)
    end
  end

  def merge_phones(employer_to_keep,employer_to_remove)
    employer_to_remove.phones.each do |phone|
      employer_to_keep.merge_phone(phone)
    end
  end

  def merge_emails(employer_to_keep,employer_to_remove)
    employer_to_remove.emails.each do |email|
      employer_to_keep.merge_email(email)
    end
  end

  def move_and_delete_employees(employer_to_keep,employer_to_remove)
    move_employees(employer_to_keep,employer_to_remove)
    set_employer_details(employer_to_keep,employer_to_remove)
    remove_employees(employer_to_remove)
  end

  def move_employees(employer_to_keep,employer_to_remove)
    employer_to_remove.employees.each do |employee|
      employer_to_keep.employees << employee.dup
    end
    employer_to_keep.save!
  end

  def set_employer_details(employer_to_keep, employer_to_remove)
    employer_to_keep.carrier_ids << employer_to_remove.carrier_ids
    employer_to_keep.carrier_ids.flatten!
    employer_to_keep.plan_ids << employer_to_remove.plan_ids
    employer_to_keep.plan_ids.flatten!
    employer_to_keep.broker_id = employer_to_remove.broker_id if employer_to_keep.broker_id.nil?
    employer_to_keep.save!
  end

  def remove_employees(employer_to_remove)
    employer_to_remove.unset(:fein)
    employer_to_remove.employees.each {|employee| employee.destroy}
    employer_to_remove.save!
  end

  def unset_employer_details(employer_to_remove)
    employer_to_remove.unset(:carrier_ids)
    employer_to_remove.unset(:plan_ids)
    employer_to_remove.unset(:broker_id)
    employer_to_remove.save!
  end

  def migrate
    employer_to_keep = Employer.find(ENV['employer_to_keep'])
    employer_to_remove = Employer.find(ENV['employer_to_remove'])
    move_and_delete_employees(employer_to_keep,employer_to_remove)
    unset_employer_details(employer_to_remove)
    merge_addresses(employer_to_keep,employer_to_remove)
    merge_phones(employer_to_keep,employer_to_remove)
    merge_emails(employer_to_keep,employer_to_remove)
    puts "Succesfully merged employers" unless Rails.env.test?
  end
end