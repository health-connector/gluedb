require "rails_helper"

describe EmployerEvents::EmployerImporter, "given an employer xml" do
  subject { EmployerEvents::EmployerImporter.new(employer_event_xml) }

  describe "with no published plan years" do
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
        </plan_years>
      </employer_profile>
      </organization>
      XML_CODE
    end

    it "is not importable" do
      expect(subject.importable?).to be_falsey
    end

    it "persists nothing" do
      subject.persist
    end
  end

  describe "with a published plan year" do
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
          <plan_year/>
        </plan_years>
      </employer_profile>
      </organization>
      XML_CODE
    end

    it "is importable" do
      expect(subject.importable?).to be_truthy
    end
  end

  describe "employer with basic information" do
    let(:employer_event_xml) do
      <<-XML_CODE
      <organization xmlns="http://openhbx.org/api/terms/1.0">
      <id>
      <id>EMPLOYER_HBX_ID_STRING</id>
      </id>
      <name>TEST NAME</name>
      <dba>TEST DBA</name>
      <fein>123456789</fein>
      </organization>
      XML_CODE
    end

    describe "the extracted employer information" do
      let(:employer_information) { subject.employer_values }

      it "is has hbx_id information" do
        expect(employer_information[:hbx_id]).to eq "EMPLOYER_HBX_ID_STRING"
      end

      it "is has name information" do
        expect(employer_information[:name]).to eq "TEST NAME"
      end

      it "is has dba information" do
        expect(employer_information[:dba]).to eq "TEST DBA"
      end

      it "is has dba information" do
        expect(employer_information[:fein]).to eq "123456789"
      end
    end
  end

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
      expect(subject.importable?).to be_truthy
    end

    describe "the extracted plan year values" do
      let(:plan_year_values) { subject.plan_year_values }

      it "has the right length" do
        expect(plan_year_values.length).to eq 2
      end

      it "has the correct start for the first plan year" do
        expect(plan_year_values.first[:start_date]).to eq(first_plan_year_start_date)
      end

      it "has the correct end for the first plan year" do
        expect(plan_year_values.first[:end_date]).to eq(first_plan_year_end_date)
      end

      it "has the correct start for the last plan year" do
        expect(plan_year_values.last[:start_date]).to eq(last_plan_year_start_date)
      end

      it "has the correct end for the last plan year" do
        expect(plan_year_values.last[:end_date]).to eq(last_plan_year_end_date)
      end
    end
  end

describe "with published plan years and carrier ids" do

  let(:first_plan_year_start_date) { Date.new(2017, 4, 1) }
  let(:first_plan_year_end_date) { Date.new(2018, 3, 31) }
  let(:last_plan_year_start_date) { Date.new(2018, 4, 1) }
  let(:last_plan_year_end_date) { Date.new(2019, 3, 31) }
  let(:employer) {instance_double(Employer)}
  let(:mongo_ids) { ["SOME MONGO ID", "SOME OTHER MONGO ID"]}

  let(:carrier) {instance_double(Carrier, hbx_carrier_id: "20011",:id=>"SOME MONGO ID")}
  let(:carrier_2) {instance_double(Carrier, hbx_carrier_id: "20012",:id=>"SOME OTHER MONGO ID")}
  let(:existing_py){instance_double(PlanYear, :start_date => Date.new(2017, 4, 1), :end_date => Date.new(2018, 3, 31))}
  let(:existing_pyvs){{start_date: Date.new(2017, 4, 1), :end_date=> Date.new(2018, 3, 31)}}
  let(:updated_plan_year) { instance_double(PlanYear,:issuer_ids =>["SOME MONGO ID", "SOME OTHER MONGO ID"])}
  
  let(:pyvs){{:start_date => first_plan_year_start_date, :end_date => first_plan_year_end_date } }
  let(:employer_event_xml) do
		<<-XMLCODE
		<plan_years xmlns="http://openhbx.org/api/terms/1.0">
    <plan_year>
    <plan_year_start>#{first_plan_year_start_date.strftime("%Y%m%d")}</plan_year_start>
    <plan_year_end>#{first_plan_year_end_date.strftime("%Y%m%d")}</plan_year_end>
    <open_enrollment_start>20151013</open_enrollment_start>
    <open_enrollment_end>20151110</open_enrollment_end>
    <benefit_groups>
    <benefit_group>
    <name>Health Insurance</name>
    <elected_plans>
    <elected_plan>
    <id>
    <id>A HIOS ID</id>
    </id>
    <name>A PLAN NAME</name>
    <active_year>2015</active_year>
    <is_dental_only>false</is_dental_only>
    <carrier>
    <id>
    <id>20011</id>
    </id>
    <name>A CARRIER NAME</name>
    </carrier>
    </elected_plan>
    <elected_plan>
    <id>
    <id>A HIOS ID</id>
    </id>
    <name>A PLAN NAME</name>
    <active_year>2015</active_year>
    <is_dental_only>false</is_dental_only>
    <carrier>
    <id>
    <id>20012</id>
    </id>
    <name>A CARRIER NAME</name>
    </carrier>
    </elected_plan>
    </elected_plans>
    </benefit_group>
    </benefit_groups>
    </plan_year>
    </plan_years>
		XMLCODE
  end
  
  before(:each) do 
    allow(Carrier).to receive(:where).with(:hbx_carrier_id => carrier.hbx_carrier_id).and_return([carrier]) 
    allow(Carrier).to receive(:where).with(:hbx_carrier_id => carrier_2.hbx_carrier_id).and_return([carrier_2]) 
  end
  
  it 'finds the correct carrier ids with two carriers' do 
    allow(employer).to receive(:id).and_return("1") 
    expect(subject.create_plan_year(pyvs, employer.id).issuer_ids).to eq( ["SOME MONGO ID", "SOME OTHER MONGO ID"])
  end
    
  it 'udpates an existing PY' do 
    allow(employer).to receive(:plan_years).and_return([existing_py]) 
    allow(existing_py).to receive(:update_attributes!).with({:issuer_ids => mongo_ids}).and_return(updated_plan_year) 
    expect(subject.update_plan_years(existing_pyvs, employer)).to eq(updated_plan_year)
  end

  end

describe "with published plan years and one carrier id" do
  let(:first_plan_year_start_date) { Date.new(2017, 4, 1) }
  let(:first_plan_year_end_date) { Date.new(2018, 3, 31) }
  let(:last_plan_year_start_date) { Date.new(2018, 4, 1) }
  let(:last_plan_year_end_date) { Date.new(2019, 3, 31) }
  let(:pyvs){{:start_date => first_plan_year_start_date, :end_date => first_plan_year_end_date } }
  let(:employer) {instance_double(Employer)}

  let(:employer_event_xml) do
		<<-XMLCODE
		<plan_years xmlns="http://openhbx.org/api/terms/1.0">
			<plan_year>
				<plan_year_start>#{first_plan_year_start_date.strftime("%Y%m%d")}</plan_year_start>
				<plan_year_end>#{first_plan_year_end_date.strftime("%Y%m%d")}</plan_year_end>
				<open_enrollment_start>20151013</open_enrollment_start>
				<open_enrollment_end>20151110</open_enrollment_end>
				<benefit_groups>
					<benefit_group>
						<name>Health Insurance</name>
						<elected_plans>
							<elected_plan>
								<id>
									<id>A HIOS ID</id>
								</id>
								<name>A PLAN NAME</name>
								<active_year>2015</active_year>
								<is_dental_only>false</is_dental_only>
								<carrier>
									<id>
										<id>20222</id>
									</id>
									<name>A CARRIER NAME</name>
								</carrier>
							</elected_plan>
            </elected_plans>
					</benefit_group>
				</benefit_groups>
       </plan_year>
     </plan_years>
		XMLCODE
  end

    it 'finds the correct carrier ids with one carrier' do 

      expect(subject.issuer_ids(pyvs)).to eq(['20222'])

    end

  end
end

RSpec.shared_context "employer importer shared persistance context" do
    let(:first_plan_year_start_date) { Date.new(2017, 4, 1) }
    let(:first_plan_year_end_date) { Date.new(2018, 3, 31) }
    let(:last_plan_year_start_date) { Date.new(2018, 4, 1) }
    let(:last_plan_year_end_date) { Date.new(2019, 3, 31) }


    let(:first_plan_year_values) do
      {
        :employer_id => employer_record_id,
        :start_date => first_plan_year_start_date,
        :end_date => first_plan_year_end_date
      }
    end

    let(:last_plan_year_values) do
      {
        :employer_id => employer_record_id,
        :start_date => last_plan_year_start_date,
        :end_date => last_plan_year_end_date
      }
    end

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

  let(:expected_employer_values) do
    {
      hbx_id: "EMPLOYER_HBX_ID_STRING",
      fein: "123456789",
      dba: "TEST DBA",
      name: "TEST NAME"
    }
  end

    let(:employer_record_id) { double }
    let(:employer_record) { instance_double(Employer, :id => employer_record_id, :plan_years => existing_plan_years) }

    before :each do
      allow(Employer).to receive(:where).with({hbx_id: "EMPLOYER_HBX_ID_STRING"}).and_return(existing_employer_records)
    end
end

describe EmployerEvents::EmployerImporter, "for a new employer, given an employer xml with published plan years" do
  include_context "employer importer shared persistance context"

  let(:existing_employer_records) { [] }
  let(:first_plan_year_record) { instance_double(PlanYear) }
  let(:last_plan_year_record) { instance_double(PlanYear) }
  let(:existing_plan_years) { [] }

  before :each do
    allow(PlanYear).to receive(:create!).with(first_plan_year_values).and_return(first_plan_year_record)
    allow(PlanYear).to receive(:create!).with(last_plan_year_values).and_return(last_plan_year_record)
    allow(Employer).to receive(:create!).with(expected_employer_values).and_return(employer_record)  
  end

  subject { EmployerEvents::EmployerImporter.new(employer_event_xml) }

  it "persists the employer with the correct attributes" do
    expect(Employer).to receive(:create!).with(expected_employer_values).and_return(employer_record)
    subject.persist
  end
  
  it "creates new plan years for the employer with the correct attributes" do
    expect(PlanYear).to receive(:create!).with(first_plan_year_values).and_return(first_plan_year_record)
    expect(PlanYear).to receive(:create!).with(last_plan_year_values).and_return(last_plan_year_record)
    subject.persist
  end
end

describe EmployerEvents::EmployerImporter, "for an existing employer with no plan years, given an employer xml with published plan years" do
  include_context "employer importer shared persistance context"

  let(:existing_employer_records) { [employer_record] }
  let(:first_plan_year_record) { instance_double(PlanYear) }
  let(:last_plan_year_record) { instance_double(PlanYear) }
  let(:existing_plan_years) { [] }

  subject { EmployerEvents::EmployerImporter.new(employer_event_xml) }

  before :each do
    allow(employer_record).to receive(:update_attributes!).with(expected_employer_values).and_return(true)
    allow(PlanYear).to receive(:create!).with(first_plan_year_values).and_return(first_plan_year_record)
    allow(PlanYear).to receive(:create!).with(last_plan_year_values).and_return(last_plan_year_record)
  end

  it "updates the employer with the correct attributes" do
    expect(employer_record).to receive(:update_attributes!).with(expected_employer_values).and_return(true)
    subject.persist
  end

  it "creates new plan years for the employer with the correct attributes" do
    expect(PlanYear).to receive(:create!).with(first_plan_year_values).and_return(first_plan_year_record)
    expect(PlanYear).to receive(:create!).with(last_plan_year_values).and_return(last_plan_year_record)
    subject.persist
  end
end

describe EmployerEvents::EmployerImporter, "for an existing employer with one overlapping plan year, given an employer xml with published plan years" do
  include_context "employer importer shared persistance context"

  let(:existing_employer_records) { [employer_record] }
  let(:first_plan_year_record) { instance_double(PlanYear, :start_date => first_plan_year_start_date, :end_date => nil, :issuer_ids => []) }
  let(:last_plan_year_record) { instance_double(PlanYear) }
  let(:existing_plan_years) { [first_plan_year_record] }

  subject { EmployerEvents::EmployerImporter.new(employer_event_xml) }

  before :each do
    allow(employer_record).to receive(:update_attributes!).with(expected_employer_values).and_return(true)
    allow(PlanYear).to receive(:create!).with(last_plan_year_values).and_return(last_plan_year_record)
  end

  it "updates the employer with the correct attributes" do
    expect(employer_record).to receive(:update_attributes!).with(expected_employer_values).and_return(true)
    subject.persist
  end

  it "creates only the one new plan year for the employer with the correct attributes" do
    expect(PlanYear).to receive(:create!).with(last_plan_year_values).and_return(last_plan_year_record)
    subject.persist
  end
end
