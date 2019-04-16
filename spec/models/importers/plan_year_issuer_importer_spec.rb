require "rails_helper"

describe Importers::PlanYearIssuerImporter, :dbclean => :after_each do
  describe '.export_csv' do

    let(:carrier) { FactoryGirl.create(:carrier) }
    let(:carrier1) { FactoryGirl.create(:carrier) }
    let(:carrier2) { FactoryGirl.create(:carrier) }
    let(:carrier3) { FactoryGirl.create(:carrier) }
    let(:carrier4) { FactoryGirl.create(:carrier) }
    let(:carrier5) { FactoryGirl.create(:carrier) }
    let!(:employer) { FactoryGirl.create(:employer_with_plan_year)}
    let!(:employer1) { FactoryGirl.create(:employer_with_plan_year)}
    let!(:employer2) { FactoryGirl.create(:employer_with_plan_year)}
    let!(:employer3) { FactoryGirl.create(:employer_with_plan_year)}
    let!(:employer4) { FactoryGirl.create(:employer_with_plan_year)}
    let!(:employer5) { FactoryGirl.create(:employer_with_plan_year)}
    let(:new_dup_plan_year) { FactoryGirl.create(:plan_year, start_date: employer5.plan_years.first.start_date,  end_date: employer5.plan_years.first.end_date) }
    let!(:employer5_plan_years) {employer5.plan_years << new_dup_plan_year}

    before do
      field_names = %w(employer_hbx_id employer_fein effective_period_start_on effective_period_end_on carrier_hbx_id carrier_fein)

      input_file_path = File.expand_path("#{Rails.root}/plan_year_data_test.csv")
      CSV.open(input_file_path, 'w', write_headers: true, headers: field_names) do |csv|
        csv << [employer.hbx_id, employer.fein, employer.plan_years.first.start_date.strftime("%Y-%m-%d"), employer.plan_years.first.end_date.strftime("%Y-%m-%d"), carrier.hbx_carrier_id, 11111]
        csv << [99999, employer1.fein, employer1.plan_years.first.start_date.strftime("%Y-%m-%d"), employer1.plan_years.first.end_date.strftime("%Y-%m-%d"), carrier1.hbx_carrier_id, 22222]
        csv << [employer2.hbx_id, employer2.fein, employer2.plan_years.first.start_date.strftime("%Y-%m-%d"), employer2.plan_years.first.end_date, 1234567, 33333]
        csv << [employer3.hbx_id, employer3.fein, (employer3.plan_years.first.start_date + 1.month).strftime("%Y-%m-%d"), employer3.plan_years.first.end_date.strftime("%Y-%m-%d"), carrier3.hbx_carrier_id, 44444]
        csv << [employer4.hbx_id, employer4.fein, employer4.plan_years.first.start_date.strftime("%Y-%m-%d"), (employer4.plan_years.first.end_date + 1.month).strftime("%Y-%m-%d"), carrier4.hbx_carrier_id, 55555]
        csv << [employer5.hbx_id, employer5.fein, employer5.plan_years.first.start_date.strftime("%Y-%m-%d"), employer5.plan_years.first.end_date.strftime("%Y-%m-%d"), carrier5.hbx_carrier_id, 66666]
      end

      subject  = Importers::PlanYearIssuerImporter.new(input_file_path)
      subject.export_csv
    end

    let!(:csv_output) { File.read "#{Rails.root}/plan_year_data_population_output.csv" }

    let!(:csv) {CSV.parse(csv_output, :headers => true)}

    context "should create output file after export" do
      
      it "shoud return true" do
        expect(File.exist?("#{Rails.root}/plan_year_data_population_output.csv")).to eq true
      end
    end

    context "when employer & plan year record found" do

      it 'should update plan year with issuer ids' do
        employer.reload
        expect(employer.plan_years.first.issuer_ids).to eq [carrier.id]
      end

      it "should return status true for CSV record 1" do
        expect(csv[0]['result']).to eq "true"
      end
    end

    context "when employer not found" do

      it 'should have return EmployerNotFoundError status for CSV record 2' do
        expect(csv[1]['result']).to eq("Importers::PlanYearIssuerImporter::EmployerNotFoundError")
      end
    end

    context "when issuer not found" do

      it 'should have return IssuerNotFoundError status for CSV record 3' do
        expect(csv[2]['result']).to eq("Importers::PlanYearIssuerImporter::IssuerNotFoundError")
      end
    end

    context "when plan year not found for employer" do

      it 'should have return EmployerPlanYearNotFoundError status for CSV record 4' do
        expect(csv[3]['result']).to eq("Importers::PlanYearIssuerImporter::EmployerPlanYearNotFoundError")
      end
    end

    context "when plan year end date not matched for plan year found" do

      it 'should have return PlanYearDateMismatchError status for CSV record 5' do
        expect(csv[4]['result']).to eq("Importers::PlanYearIssuerImporter::PlanYearDateMismatchError")
      end
    end

    context "when more than one plan year for the start date" do

      it 'should have return EmployerMultiplePlanYearsError status for CSV record 6 ' do
        expect(csv[5]['result']).to eq("Importers::PlanYearIssuerImporter::EmployerMultiplePlanYearsError")
      end
    end

    after :all do
      File.delete("#{Rails.root}/plan_year_data_population_output.csv") if File.exist?("#{Rails.root}/plan_year_data_population_output.csv")
      File.delete("#{Rails.root}/plan_year_data_test.csv") if File.exist?("#{Rails.root}/plan_year_data_test.csv")
    end
  end
end
