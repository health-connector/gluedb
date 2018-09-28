require "rails_helper"

describe EmployerEvents::EmployerImporter, "given an employer xml" do
  subject { EmployerEvents::EmployerImporter.new(employer_event_xml, event_name) }

  describe "with no published plan years" do
    let(:event_name) do 
      "urn:openhbx:events:v1:employer#created"
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
          </plan_years>
        </employer_profile>
        <contacts>
          <contact>
            <addresses>
              <address>
                <type>work</type>
                <address_line_1>12 Downing</address_line_1>
                <address_line_2>23 Taft </address_line_2>
                <location_city_name>Washington </location_city_name>
                <location_state_code>DC</location_state_code>
                <postal_code>12344</postal_code>
              </address>
            </addresses>
            <phones>
              <phone>
                <type>home</type>
                <full_phone_number>123322222</full_phone_number>
                <is_preferred>true</is_preferred>
              </phone>
            </phones>
            <id>
              <id>123344</id>
            </id>
            <job_title>rector</job_title>
            <department>hr</department>
            <person_name>
              <person_given_name>Dan</person_given_name>
              <person_middle_name>l</person_middle_name>
              <person_surname>Smith</person_surname>
              <person_name_suffix_text>Sr.</person_name_suffix_text>
              <person_name_prefix_text> Mr.</person_name_prefix_text>
            </person_name>
          </contact>
        </contacts>
        <office_locations>
          <office_location>
            <id>
              <id>55fc838254726568cd018d01</id>
            </id>
            <primary>true</primary>
            <name>Work</name>
            <addresses>
              <address>
                <type>work</type>
                <address_line_1>12 Downing</address_line_1>
                <address_line_2>23 Taft </address_line_2>
                <location_city_name>Washington </location_city_name>
                <location_state_code>DC</location_state_code>
                <postal_code>12344</postal_code>
              </address>
            </addresses>
            <phones>
              <phone>
                <type>home</type>
                <full_phone_number>123322222</full_phone_number>
                <is_preferred>true</is_preferred>
              </phone>
            </phones>
          </office_location>
        </office_locations> 
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
    let(:event_name) do 
      "urn:openhbx:events:v1:employer#created"
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
            <plan_year/>
          </plan_years>
        </employer_profile>
        <contacts>
          <contact>
            <addresses>
              <address>
                <type>work</type>
                <address_line_1>12 Downing</address_line_1>
                <address_line_2>23 Taft </address_line_2>
                <location_city_name>Washington </location_city_name>
                <location_state_code>DC</location_state_code>
                <postal_code>12344</postal_code>
              </address>
            </addresses>
            <phones>
              <phone>
                <type>home</type>
                <full_phone_number>123322222</full_phone_number>
                <is_preferred>true</is_preferred>
              </phone>
            </phones>
            <id>
              <id>123344</id>
            </id>
            <job_title>rector</job_title>
            <department>hr</department>
            <person_name>
              <person_given_name>Dan</person_given_name>
              <person_middle_name>l</person_middle_name>
              <person_surname>Smith</person_surname>
              <person_name_suffix_text>Sr.</person_name_suffix_text>
              <person_name_prefix_text> Mr.</person_name_prefix_text>
            </person_name>
          </contact>
        </contacts>
        <office_locations>
          <office_location>
            <id>
              <id>55fc838254726568cd018d01</id>
            </id>
            <primary>true</primary>
            <name>Work</name>
            <addresses>
              <address>
                <type>work</type>
                <address_line_1>12 Downing</address_line_1>
                <address_line_2>23 Taft </address_line_2>
                <location_city_name>Washington </location_city_name>
                <location_state_code>DC</location_state_code>
                <postal_code>12344</postal_code>
              </address>
            </addresses>
            <phones>
              <phone>
                <type>home</type>
                <full_phone_number>123322222</full_phone_number>
                <is_preferred>true</is_preferred>
              </phone>
            </phones>
          </office_location>
        </office_locations> 

      </organization>
      XML_CODE
    end

    it "is importable" do
      expect(subject.importable?).to be_truthy
    end
  end

  describe "employer with basic information" do
    let(:event_name) do 
      "urn:openhbx:events:v1:employer#created"
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

      </organization>
      XML_CODE
    end

    describe "the extracted employer information" do
      let(:event_name) do 
        "urn:openhbx:events:v1:employer#created"
      end
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
    let(:event_name) do 
      "urn:openhbx:events:v1:employer#created"
    end
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
        <contacts>
          <contact>
            <addresses>
              <address>
                <type>work</type>
                <address_line_1>12 Downing</address_line_1>
                <address_line_2>23 Taft </address_line_2>
                <location_city_name>Washington </location_city_name>
                <location_state_code>DC</location_state_code>
                <postal_code>12344</postal_code>
              </address>
            </addresses>
            <phones>
              <phone>
                <type>home</type>
                <full_phone_number>123322222</full_phone_number>
                <is_preferred>true</is_preferred>
              </phone>
            </phones>
            <id>
              <id>123344</id>
            </id>
            <job_title>rector</job_title>
            <department>hr</department>
            <person_name>
              <person_given_name>Dan</person_given_name>
              <person_middle_name>l</person_middle_name>
              <person_surname>Smith</person_surname>
              <person_name_suffix_text>Sr.</person_name_suffix_text>
              <person_name_prefix_text> Mr.</person_name_prefix_text>
            </person_name>
          </contact>
        </contacts>
        <office_locations>
          <office_location>
            <id>
              <id>55fc838254726568cd018d01</id>
            </id>
            <primary>true</primary>
            <name>Work</name>
            <addresses>
              <address>
                <type>work</type>
                <address_line_1>12 Downing</address_line_1>
                <address_line_2>23 Taft </address_line_2>
                <location_city_name>Washington </location_city_name>
                <location_state_code>DC</location_state_code>
                <postal_code>12344</postal_code>
              </address>
            </addresses>
            <phones>
              <phone>
                <type>home</type>
                <full_phone_number>123322222</full_phone_number>
                <is_preferred>true</is_preferred>
              </phone>
            </phones>
          </office_location>
        </office_locations> 
      </organization>
      XML_CODE
    end

    it "is importable" do
      expect(subject.importable?).to be_truthy
    end

    describe "the extracted plan year values" do
      let(:event_name) do 
        "urn:openhbx:events:v1:employer#created"
      end
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
end

RSpec.shared_context "employer importer shared persistance context" do
  let(:event_name) do 
    "urn:openhbx:events:v1:employer#created"
  end 
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
        <contacts>
          <contact>
            <addresses>
              <address>
                <type>work</type>
                <address_line_1>12 Downing</address_line_1>
                <address_line_2>23 Taft </address_line_2>
                <location_city_name>Washington </location_city_name>
                <location_state_code>DC</location_state_code>
                <postal_code>12344</postal_code>
              </address>
            </addresses>
            <phones>
              <phone>
                <type>home</type>
                <full_phone_number>123322222</full_phone_number>
                <is_preferred>true</is_preferred>
              </phone>
            </phones>
            <id>
              <id>123344</id>
            </id>
            <job_title>rector</job_title>
            <department>hr</department>
            <person_name>
              <person_given_name>Dan</person_given_name>
              <person_middle_name>l</person_middle_name>
              <person_surname>Smith</person_surname>
              <person_name_suffix_text>Sr.</person_name_suffix_text>
              <person_name_prefix_text> Mr.</person_name_prefix_text>
            </person_name>
          </contact>
        </contacts>
        <office_locations>
          <office_location>
            <id>
              <id>55fc838254726568cd018d01</id>
            </id>
            <primary>true</primary>
            <name>Work</name>
            <addresses>
              <address>
                <type>work</type>
                <address_line_1>12 Downing</address_line_1>
                <address_line_2>23 Taft </address_line_2>
                <location_city_name>Washington </location_city_name>
                <location_state_code>DC</location_state_code>
                <postal_code>12344</postal_code>
              </address>
            </addresses>
            <phones>
              <phone>
                <type>home</type>
                <full_phone_number>123322222</full_phone_number>
                <is_preferred>true</is_preferred>
              </phone>
            </phones>
          </office_location>
        </office_locations> 
      </organization>
      XML_CODE
    end

    let(:employer_event_xml_multiple_contacts) do
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
        <contacts>
          <contact>
            <addresses>
              <address>
                <type>work</type>
                <address_line_1>12 Downing</address_line_1>
                <address_line_2>23 Taft </address_line_2>
                <location_city_name>Washington </location_city_name>
                <location_state_code>DC</location_state_code>
                <postal_code>12344</postal_code>
              </address>
            </addresses>
            <phones>
              <phone>
                <type>home</type>
                <full_phone_number>123322222</full_phone_number>
                <is_preferred>true</is_preferred>
              </phone>
              <phone>
                <type>work</type>
                <full_phone_number>11111111</full_phone_number>
                <is_preferred>true</is_preferred>
              </phone>
            </phones>
            <id>
              <id>123344</id>
            </id>
            <job_title>rector</job_title>
            <department>hr</department>
            <person_name>
              <person_given_name>Dan</person_given_name>
              <person_middle_name>l</person_middle_name>
              <person_surname>Smith</person_surname>
              <person_name_suffix_text>Sr.</person_name_suffix_text>
              <person_name_prefix_text> Mr.</person_name_prefix_text>
            </person_name>
          </contact>
          <contact>
            <addresses>
              <address>
                <type>work</type>
                <address_line_1>12 Downing</address_line_1>
                <address_line_2>23 Taft </address_line_2>
                <location_city_name>Washington </location_city_name>
                <location_state_code>DC</location_state_code>
                <postal_code>12344</postal_code>
              </address>
            </addresses>
            <phones>
              <phone>
                <type>home</type>
                <full_phone_number>123322222</full_phone_number>
                <is_preferred>true</is_preferred>
              </phone>
              <phone>
                <type>work</type>
                <full_phone_number>11111111</full_phone_number>
                <is_preferred>true</is_preferred>
              </phone>
            </phones>
            <id>
              <id>123344</id>
            </id>
            <job_title>rector</job_title>
            <department>hr</department>
            <person_name>
              <person_given_name>Dan</person_given_name>
              <person_middle_name>l</person_middle_name>
              <person_surname>Smith</person_surname>
              <person_name_suffix_text>Sr.</person_name_suffix_text>
              <person_name_prefix_text> Mr.</person_name_prefix_text>
            </person_name>
          </contact>
        </contacts>
        <office_locations>
          <office_location>
            <id>
              <id>55fc838254726568cd018d01</id>
            </id>
            <primary>true</primary>
            <name>Work</name>
            <addresses>
              <address>
                <type>work</type>
                <address_line_1>12 Downing</address_line_1>
                <address_line_2>23 Taft </address_line_2>
                <location_city_name>Washington </location_city_name>
                <location_state_code>DC</location_state_code>
                <postal_code>12344</postal_code>
              </address>
            </addresses>
            <phones>
              <phone>
                <type>home</type>
                <full_phone_number>123322222</full_phone_number>
                <is_preferred>true</is_preferred>
              </phone>

            </phones>
          </office_location>
        </office_locations> 
      </organization>
      XML_CODE
    end

    let(:employer_event_xml_multiple_office_locations) do
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
        <contacts>
          <contact>
            <addresses>
              <address>
                <type>work</type>
                <address_line_1>12 Downing</address_line_1>
                <address_line_2>23 Taft </address_line_2>
                <location_city_name>Washington </location_city_name>
                <location_state_code>DC</location_state_code>
                <postal_code>12344</postal_code>
              </address>
            </addresses>
            <id>
              <id>123344</id>
            </id>
            <job_title>rector</job_title>
            <department>hr</department>
            <person_name>
              <person_given_name>Dan</person_given_name>
              <person_middle_name>l</person_middle_name>
              <person_surname>Smith</person_surname>
              <person_name_suffix_text>Sr.</person_name_suffix_text>
              <person_name_prefix_text> Mr.</person_name_prefix_text>
            </person_name>
          </contact>
        </contacts>
        <office_locations>
          <office_location>
            <id>
              <id>55fc838254726568cd018d01</id>
            </id>
            <primary>true</primary>
            <name>Work</name>
            <addresses>
              <address>
                <type>work</type>
                <address_line_1>12 Downing</address_line_1>
                <address_line_2>23 Taft </address_line_2>
                <location_city_name>Washington </location_city_name>
                <location_state_code>DC</location_state_code>
                <postal_code>12344</postal_code>
              </address>
            </addresses>
            <phones>
              <phone>
                <type>home</type>
                <full_phone_number>123322222</full_phone_number>
                <is_preferred>true</is_preferred>
              </phone>
            </phones>
          </office_location>
        </office_locations> 
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
  let(:employer_record) { instance_double(Employer, :id => employer_record_id, :plan_years => existing_plan_years,addresses:addresses) }
  let(:address) { instance_double(Address) }
  let(:addresses) { [ address ] }
  let(:phone) { instance_double(Phone) }
  let(:phones) { [ phone ] }

  before :each do
    allow(employer_record).to receive(:employer_contacts).and_return([]) 
    allow(employer_record).to receive(:employer_office_locations).and_return([])

    allow(Employer).to receive(:where).with({hbx_id: "EMPLOYER_HBX_ID_STRING"}).and_return(existing_employer_records)
    allow(address).to receive(:update_attributes!).and_return(address)
    allow(phone).to receive(:update_attributes!).and_return(phone)
  end

end

describe EmployerEvents::EmployerImporter, "for a new employer, given an employer xml with published plan years" do
  include_context "employer importer shared persistance context"
  
  let(:existing_employer_records) { [] }
  let(:first_plan_year_record) { instance_double(PlanYear) }
  let(:last_plan_year_record) { instance_double(PlanYear) }
  let(:existing_plan_years) { [] }
    
  before :each do
    allow(Employer).to receive(:create!).with(expected_employer_values).and_return(employer_record)
    allow(employer_record).to receive(:employer_contacts).and_return([]) 
    allow(employer_record).to receive(:employer_office_locations).and_return([])
    allow(employer_record).to receive(:save!).and_return(employer_record)
    allow(PlanYear).to receive(:create!).with(first_plan_year_values).and_return(first_plan_year_record)
    allow(PlanYear).to receive(:create!).with(last_plan_year_values).and_return(last_plan_year_record)
  end
  
  subject { EmployerEvents::EmployerImporter.new(employer_event_xml, event_name) }
  
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

  subject { EmployerEvents::EmployerImporter.new(employer_event_xml, event_name) }

  before :each do
    allow(employer_record).to receive(:employer_contacts).and_return([]) 
    allow(employer_record).to receive(:employer_office_locations).and_return([])
    allow(employer_record).to receive(:save!).and_return(employer_record)
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
  
  
  
  
  describe EmployerEvents::EmployerImporter, "for an existing employer with one overlapping plan year, given an employer xml with published plan years" do
    
    let(:existing_employer_records) { [employer_record] }
    let(:first_plan_year_record) { instance_double(PlanYear, :start_date => first_plan_year_start_date, :end_date => nil) }
    let(:last_plan_year_record) { instance_double(PlanYear) }
    let(:existing_plan_years) { [first_plan_year_record] }
    let(:contact) {instance_double(EmployerContact)}
    let(:office_location) {instance_double(EmployerOfficeLocation)}

    subject { EmployerEvents::EmployerImporter.new(employer_event_xml_multiple_contacts, event_name) }
    
    before :each do
      allow(employer_record).to receive(:update_attributes!).with(expected_employer_values).and_return(true)
      allow(PlanYear).to receive(:create!).with(last_plan_year_values).and_return(last_plan_year_record)
      allow(employer_record).to receive(:employer_contacts).and_return([]) 
      allow(employer_record).to receive(:employer_office_locations).and_return([])
      allow(employer_record).to receive(:save!).and_return(employer_record)
      allow(employer_record).to receive(:employer_contacts).and_return([]) 
    end
    
    it "employer can have employer_contacts created" do
      expect(employer_record.employer_contacts.count).to eq 0
      
      subject.persist 
      
      expect(employer_record.employer_contacts.count).to eq 2
    end
    it "employer can add phones to one of the created contacts" do
      subject.persist 
      
      expect(employer_record.employer_contacts.first.phones.size).to eq 2
      expect(employer_record.employer_contacts.first.phones.pop.class).to eq Phone

    end
    it "employer can add addresses to one of the created contacts" do
      subject.persist 
      
      expect(employer_record.employer_contacts.first.addresses.size).to eq 1
      expect(employer_record.employer_contacts.first.addresses.pop.class).to eq Address

    end
  end
  
  describe EmployerEvents::EmployerImporter, "for an existing employer with one overlapping plan year, given an employer xml with published plan years" do
    
    let(:existing_employer_records) { [employer_record] }
    let(:first_plan_year_record) { instance_double(PlanYear, :start_date => first_plan_year_start_date, :end_date => nil) }
    let(:last_plan_year_record) { instance_double(PlanYear) }
    let(:existing_plan_years) { [first_plan_year_record] }
    let(:contact) {instance_double(EmployerContact)}
    let(:office_location) {instance_double(EmployerOfficeLocation)}

    subject { EmployerEvents::EmployerImporter.new(employer_event_xml_multiple_office_locations, event_name) }
    
    before :each do
      allow(employer_record).to receive(:update_attributes!).with(expected_employer_values).and_return(true)
      allow(PlanYear).to receive(:create!).with(last_plan_year_values).and_return(last_plan_year_record)
      allow(employer_record).to receive(:employer_contacts).and_return([]) 
      allow(employer_record).to receive(:employer_office_locations).and_return([])
      allow(employer_record).to receive(:save!).and_return(employer_record)
      allow(employer_record).to receive(:employer_contacts).and_return([]) 
    end
    
      # it "employer can have employer_contacts created" do
      #   expect(employer_record.employer_office_locations.count).to eq 0
        
      #   subject.persist 
        
      #   expect(employer_record.employer_office_locations.count).to eq 2
      # end
    # it "employer can add phones to one of the created office_locations" do
    #   subject.persist 
      
    #   expect(employer_record.employer_office_locations.first.phones.size).to eq 2
    #   expect(employer_record.employer_office_locations.first.phones.pop.class).to eq Phone

    # end
    # it "employer can add addresses to one of the created office_locations" do
    #   subject.persist 
      
    #   expect(employer_record.employer_office_locations.first.addresses.size).to eq 1
    #   expect(employer_record.employer_office_locations.first.addresses.pop.class).to eq Address

    # end
  end
end