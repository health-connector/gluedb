# Changes the employer on a policy
require File.join(Rails.root, "lib/mongoid_migration_task")
class ChangePolicyEmployer < MongoidMigrationTask

  def migrate
    employer_id = ENV['employer_id']
    employer = Employer.find(employer_id)
    eg_ids=ENV['eg_ids'].split(',').uniq
    eg_ids.each do |eg_id|
      policy = Policy.where(eg_id: eg_id).first
      if policy.present? && employer.present?
        policy.update_attributes!(employer_id: employer_id)
        policy.save!
        puts "Successfully update eg_id:#{eg_id} with its employer_id:#{employer_id}" unless Rails.env.test?
      else
        puts "Couldn't find employer with its id:#{ENV['mongo_id']} or policy with its eg_id:#{ENV['eg_id']}" unless Rails.env.test?
      end
    end
  end
end