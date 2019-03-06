require 'csv'

class Importers::PlanYearIssuerImporter

  def initialize(file_path)
    csv_path = File.read(file_path)
    @csv = CSV.parse(csv_path, :headers => true)
  end

  def export_csv
    field_names = %w(employer_hbx_id employer_fein plan_year_start plan_year_end carrier_hbx_id carrier_fein status)
    file_name = "#{Rails.root}/plan_year_data_population_output.csv"

    CSV.open(file_name, "w", force_quotes: true) do |csv_output|
      csv_output << field_names
      @csv.each do |row|
        status = get_status_for(row)
        csv_output << [row['employer_hbx_id'], row['employer_fein'], row['plan_year_start'], row['plan_year_end'], row['carrier_hbx_id'], row['carrier_fein'], status]
      end
    end
  end

  def get_status_for(row)
    employer_hbx_id = row['employer_hbx_id']
    carrier_hbx_id = row['carrier_hbx_id']
    plan_year_start = Date.strptime(row['effective_period_start_on'], "%m-%d-%Y")
    plan_year_end = Date.strptime(row['effective_period_end_on'], "%m-%d-%Y")

    carrier =  Carrier.where(hbx_carrier_id: carrier_hbx_id).first
    employer = Employer.by_hbx_id(employer_hbx_id).first
    plan_years = employer.plan_years.by_start_date(plan_year_start) if employer.present? 

    return "Employer not found" if employer.blank?
    return "Carrier not found" if carrier.blank?
    return "Plan Year not found" if plan_years.empty?
    return "Found More than one plan year" if plan_years.count > 1
    return "Plan Year end date didn't matched for the found plan year" if plan_years.count == 1 && plan_years.first.end_date != plan_year_end

    found_plan_year = plan_years.first

    if found_plan_year.issuer_ids.include?(carrier.hbx_carrier_id)
      return "plan year found and carrier hbx_id already exists in issuer_ids"
    else
      found_plan_year.issuer_ids << carrier.hbx_carrier_id
      found_plan_year.save
      return "Plan Year found and sucessfully updated plan year issuer_ids"
    end
  end
end
