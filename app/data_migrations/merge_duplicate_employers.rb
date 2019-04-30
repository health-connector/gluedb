
require File.join(Rails.root, "lib/mongoid_migration_task")

class MergeDuplicateEmployers < MongoidMigrationTask
  def migrate
    if ENV['csv_file'] == "true"
      file_name = (
                    if Rails.env.production? 
                      "#{Rails.root}/duplicate_employer_records.csv" 
                    elsif Rails.env.test?
                      "#{Rails.root}/spec/data_migrations/test_duplicate_employer_records.csv"
                    end
                    )
      update_duplicate_employers_with_csv(file_name)
    elsif ENV['csv_file'] == "false"
      update_duplicate_employers_without_csv
    else 
      puts "Could not find CSV FILE or did not pass environment variables" unless Rails.env.test?
    end
  end

  def update_duplicate_employers_without_csv
    employer_to_keep = Employer.find(ENV['employer_to_keep'])
    employer_to_remove = Employer.find(ENV['employer_to_remove'])
    merge_duplicate_employers(employer_to_keep,employer_to_remove)
  end

  def update_duplicate_employers_with_csv(file_name)
    CSV.read(file_name).each do |row|
      next if CSV.read(file_name)[0] == row
      row = row.compact
      next if row.length == 0
      fein = row[1]
      employer_to_keep_id = row[3]
      employer_to_remove_id = row[4]
      employer_to_keep = Employer.find(employer_to_keep_id)
      employer_to_remove = Employer.find(employer_to_remove_id)
      if employer_to_keep.present? && employer_to_remove.present? 
        merge_duplicate_employers(employer_to_keep,employer_to_remove)
      else
        puts "Could not find Employer with either #{employer_to_keep_id} or #{employer_to_remove_id}" unless Rails.env.test?
      end
    end
  end

  def merge_duplicate_employers(employer_to_keep,employer_to_remove)
    move_and_delete_employees(employer_to_keep,employer_to_remove)
    unset_employer_details(employer_to_remove)
    merge_addresses(employer_to_keep,employer_to_remove)
    merge_phones(employer_to_keep,employer_to_remove)
    merge_emails(employer_to_keep,employer_to_remove)
  end

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
    if employer_to_remove.employees.present?
      employer_to_remove.employees.each do |employee|
        employer_to_keep.employees << employee.dup
      end
    end
    employer_to_keep.save!
  end

  def set_employer_details(employer_to_keep, employer_to_remove)
    if employer_to_remove.carrier_ids.present?
      employer_to_keep.carrier_ids << employer_to_remove.carrier_ids
      employer_to_keep.carrier_ids.flatten!
    end
    if employer_to_remove.plan_ids.present?
      employer_to_keep.plan_ids << employer_to_remove.plan_ids
      employer_to_keep.plan_ids.flatten!
    end
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
    org_name = employer_to_remove.name
    employer_to_remove.update_attributes!(name: "do_not_use_"+ "#{org_name}")
    employer_to_remove.save!
  end
end