require "rails_helper"

describe EmployerEvents::EmployerImporter, "given an employer xml" do
  subject { EmployerEvents::EmployerImporter.new(employer_event_xml) }
  let!(:employer) { FactoryGirl.create(:employer_with_plan_year)}



  describe "with multiple published plan years" do
    let(:first_plan_year_start_date) { Date.new(2017, 4, 1) }
    let(:first_plan_year_end_date) { Date.new(2018, 3, 31) }
    let(:last_plan_year_start_date) { Date.new(2018, 4, 1) }
    let(:last_plan_year_end_date) { Date.new(2019, 3, 31) }

    let(:employer_event_xml) do
      <<-XML_CODE
      <organization xmlns="http://openhbx.org/api/terms/1.0">
      <id>
      <id>EMPLOYER_HBX_ID_STRING</id>
      </id>
      <name>TEST NAME</name>
      <dba>TEST DBA</name>
      <fein>123456789</fein>
      <employer_profile>
        <plan_years>
          <plan_year>
            <plan_year_start>#{first_plan_year_start_date.strftime("%Y%m%d")}</plan_year_start>
            <plan_year_end>#{first_plan_year_end_date.strftime("%Y%m%d")}</plan_year_end>
          </plan_year>
          <plan_year>
            <plan_year_start>#{last_plan_year_start_date.strftime("%Y%m%d")}</plan_year_start>
            <plan_year_end>#{last_plan_year_end_date.strftime("%Y%m%d")}</plan_year_end>
          </plan_year>
        </plan_years>
      </employer_profile>
      </organization>
      XML_CODE
    end

    it "is importable" do
      EmployerEvent.create_plan_years(subject)
      expect(subject.importable?).to be_truthy
    end


  end
end
