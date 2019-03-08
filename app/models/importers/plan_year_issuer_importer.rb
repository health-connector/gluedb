require 'csv'

module Importers
  class PlanYearIssuerImporter

    class EmployerPlanYearNotFoundError < StandardError
    end

    class EmployerMultiplePlanYearsError < StandardError
    end

    class EmployerNotFoundError < StandardError
    end

    class IssuerNotFoundError < StandardError
    end

    class PlanYearDateMismatchError < StandardError
    end

  def initialize(file_path)
    @csv_path = file_path
    @issuer_map = Hash.new
    Carrier.all.each do |c|
      @issuer_map[c.hbx_carrier_id] = c
    end
  end

  def export_csv
    headers = [
      "employer_hbx_id",
      "employer_fein",
      "effective_period_start_on",
      "effective_period_end_on",
      "carrier_hbx_id",
      "carrier_fein",
      "result"
    ]
    file_name = "#{Rails.root}/plan_year_data_population_output.csv"

    CSV.open(file_name, "w") do |csv_output|
      csv_output << headers
      CSV.foreach(@csv_path, :headers => true) do |in_row|
        result = begin
                   process_row(in_row)
                 rescue => e
                   "#{e.class.name}"
                 end

        csv_output << (in_row.to_a + [result])
      end
    end
  end

  def process_row(row)
    employer_hbx_id = row['employer_hbx_id']
    carrier_hbx_id = row['carrier_hbx_id']
    plan_year_start = Date.strptime(row['effective_period_start_on'], "%Y-%m-%d") rescue nil
    plan_year_end = Date.strptime(row['effective_period_end_on'], "%Y-%m-%d") rescue nil
    
    employer = Employer.by_hbx_id(employer_hbx_id).first
    raise EmployerNotFoundError.new unless employer

    issuer = @issuer_map[carrier_hbx_id]
    raise IssuerNotFoundError.new unless issuer

    plan_years = PlanYear.for_employer_starting_on(employer, plan_year_start)
    raise EmployerPlanYearNotFoundError.new if plan_years.empty?

    if plan_years.many?
      select_end_date_matches = plan_years.select do |py|
        py.end_date == plan_year_end
      end
      raise EmployerMultiplePlanYearsError.new if select_end_date_matches.many?
      raise PlanYearDateMismatchError.new if select_end_date_matches.empty?
      plan_year = select_end_date_matches.first
      raise PlanYearDateMismatchError.new if (plan_year.end_date != plan_year_end)
      plan_year.add_issuer(issuer)
    else
      plan_year = plan_years.first
      raise PlanYearDateMismatchError.new if (plan_year.end_date != plan_year_end)
      plan_year.add_issuer(issuer)
    end
  end
end
end
