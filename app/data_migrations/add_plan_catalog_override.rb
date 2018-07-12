# Adds override catalog thing
require File.join(Rails.root, "lib/mongoid_migration_task")

class AddPlanCatalogOverride < MongoidMigrationTask
  def find_plan_year(fein,plan_year_start)
    employer = Employer.where(fein: fein.to_s).first
    return nil if employer.blank?
    plan_year = employer.plan_years.detect{|py| py.start_date == plan_year_start}
    return plan_year
  end

  def add_override(plan_year,override_integer)
    plan_year.update_attributes(:plan_catalog_override => override_integer)
  end

  def migrate

    CSV.foreach(ENV['filename'],headers: true) do |row|
      data = row.to_hash
      fein = data["FEIN"].to_s
      plan_year_start = Date.strptime(data['Start Date'], '%m-%d-%Y')
      plan_year = find_plan_year(fein,plan_year_start) 

      if plan_year.blank?
        puts "Plan Year Not Found for #{fein} and start date #{plan_year_start}."
      else
        add_override(plan_year,data['override_integer'].to_i)
      end
    end

  end
end
