require File.join(Rails.root, "lib/mongoid_migration_task")
class RemoveIssuerIdsFromPlanYear < MongoidMigrationTask

  def migrate
    hbx_id = ENV["hbx_id"]
    start_date = ENV["start_date"]
    issuer_id = ENV["issuer_id"]

    employer = Employer.where(hbx_id: hbx_id).first

    if employer.blank?
      puts "No employer was found with the given hbx_id: #{hbx_id} " unless Rails.env.test?
    else
      plan_year = employer.plan_years.where(start_date: start_date).first
      if plan_year.present?
        issuer = plan_year.issuers.delete_if{|issuer| issuer.id.to_s == issuer_id}
        plan_year.issuer_ids = issuer.map(&:id)
        plan_year.save
        puts "Successfully updated issuer ids for plan_year with start_date:#{plan_year.start_date} and end_date:#{plan_year.end_date}" unless Rails.env.test?
      else
        puts "Plan_year is not found for the employer: #{hbx_id}" unless Rails.env.test?
      end
    end
  end
end
