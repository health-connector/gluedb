# Cleans up instances of duplicate employers
require File.join(Rails.root, "lib/mongoid_migration_task")

class DuplicateEmployerCleanup < MongoidMigrationTask

  def move_plan_years
    bad_employer = Employer.find(ENV['bad_employer_id'])
    good_employer = Employer.find(ENV['good_employer_id'])

    raise "One of the employers was not found" if (bad_employer.blank? || good_employer.blank?)

    bad_employer.plan_years.each do |py|
      good_employer.merge_plan_year(py)
    end
  end

  def move_premium_payments
    bad_employer = Employer.find(ENV['bad_employer_id'])
    good_employer = Employer.find(ENV['good_employer_id'])

    raise "One of the employers was not found. Please check your mongo IDs." if (bad_employer.blank? || good_employer.blank?)

    bad_employer.premium_payments.each do |pp|
      pp.employer = good_employer
      pp.save
    end
  end

  def update_bad_employer_name
    bad_employer = Employer.find(ENV['bad_employer_id'])
    bad_employer.name = "OLD DO NOT USE " + bad_employer.name
    bad_employer.save
  end

  def move_addresses
    bad_employer = Employer.find(ENV['bad_employer_id'])
    good_employer = Employer.find(ENV['good_employer_id'])
    bad_employer.addresses.each do |address|
      good_employer.merge_address(address)
    end
  end

  def move_phones
    bad_employer = Employer.find(ENV['bad_employer_id'])
    good_employer = Employer.find(ENV['good_employer_id'])
    bad_employer.phones.each do |phone|
      good_employer.merge_phone(phone)
    end
  end

  def move_emails
    bad_employer = Employer.find(ENV['bad_employer_id'])
    good_employer = Employer.find(ENV['good_employer_id'])
    bad_employer.emails.each do |email|
      good_employer.merge_email(email)
    end
  end

  def move_policies
    bad_employer_policies = Policy.where(employer_id: ENV['bad_employer_id'])
    good_employer = Employer.find(ENV['good_employer_id'])
    bad_employer_policies.each do |policy|
      policy.employer = good_employer
      policy.save
    end
  end

  def migrate
    move_plan_years
    move_premium_payments
    move_addresses
    move_phones
    move_emails
    move_policies
    update_bad_employer_name
  end
end