require "rails_helper"

describe Importers::PlanYearIssuerImporter, :dbclean => :after_each do
  describe '.export_csv' do

    let(:carrier1) { FactoryGirl.create(:carrier) }
    let(:carrier2) { FactoryGirl.create(:carrier) }

    let!(:employer) { FactoryGirl.create(:employer_with_plan_year)}
    let!(:employer1) { FactoryGirl.create(:employer_with_plan_year)}


    before do
      field_names = %w(employer_hbx_id employer_fein effective_period_start_on effective_period_end_on carrier_hbx_id carrier_fein)

      input_file_path = File.expand_path("#{Rails.root}/plan_year_data_test.csv")
      CSV.open(input_file_path, 'w', write_headers: true, headers: field_names) do |csv|
        csv << [employer.hbx_id, employer.fein, employer.plan_years.first.start_date, employer.plan_years.first.end_date, carrier1.hbx_carrier_id, 3333333]
        csv << [employer1.hbx_id, employer1.fein, employer1.plan_years.first.start_date, employer1.plan_years.first.end_date + 1.month, 1111, 12344]

      end

      subject  = Importers::PlanYearIssuerImporter.new(input_file_path)
      subject.export_csv
    end

    let!(:csv_output) { File.read "#{Rails.root}/plan_year_data_population_output.csv" }

    let!(:csv) {CSV.parse(csv_output, :headers => true)}

    it 'should update plan year with issuer ids for employer1' do
      employer.reload
      expect(employer.plan_years.first.issuer_ids).to eq [carrier1.hbx_carrier_id]
    end

    it 'should write status message for record 1' do
      expect(csv[0]['status']).to eq("Plan Year found and sucessfully updated plan year issuer_ids")
    end

    it 'should write failure message for failure for record 2' do
      expect(csv[1]['status']).to eq("Carrier not found")
    end

    after :all do
      File.delete("#{Rails.root}/plan_year_data_population_output.csv") if File.exist?("#{Rails.root}/plan_year_data_population_output.csv")
      File.delete("#{Rails.root}/plan_year_data_test.csv") if File.exist?("#{Rails.root}/plan_year_data_test.csv")
    end
  end
end