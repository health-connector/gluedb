require "rails_helper"

describe EmployerEvents::EmployerImporter, "given an employer xml" do
  subject { EmployerEvents::EmployerImporter.new(employer_event_xml, event_name) }

  describe "with no published plan years" do
    let(:event_name) do
      "urn:openhbx:events:v1:employer#contact_changed"
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
            <addresses>
              <address>
                <type>urn:openhbx:terms:v1:address_type#work</type>
                <address_line_1>123 Downing</address_line_1>
                <address_line_2>23 Taft </address_line_2>
                <location_city_name>Washington </location_city_name>
                <location_state_code>DC</location_state_code>
                <postal_code>12344</postal_code>
              </address>
            </addresses>
            <phones>
              <phone>
                <type>urn:openhbx:terms:v1:phone_type#home</type>
                <full_phone_number>123322222</full_phone_number>
                <is_preferred></is_preferred>
              </phone>
            </phones>
          </contact>
        </contacts>
        <office_locations>
          <office_location>
            <id>
              <id>55fc838254726568cd018d01</id>
            </id>
            <primary>true</primary>
            <name>Work</name>
              <address>
                <type>urn:openhbx:terms:v1:address_type#work</type>
                <address_line_1>12 Downing</address_line_1>
                <address_line_2>23 Taft </address_line_2>
                <location_city_name>Washington </location_city_name>
                <location_state_code>DC</location_state_code>
                <postal_code>12344</postal_code>
              </address>
              <phone>
                <type>urn:openhbx:terms:v1:phone_type#home</type>
                <full_phone_number>123322222</full_phone_number>
                <is_preferred></is_preferred>
              </phone>
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
      "urn:openhbx:events:v1:employer#contact_changed"
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
                <type>urn:openhbx:terms:v1:address_type#work</type>
                <address_line_1>12 Downing</address_line_1>
                <address_line_2>23 Taft </address_line_2>
                <location_city_name>Washington </location_city_name>
                <location_state_code>DC</location_state_code>
                <postal_code>12344</postal_code>
              </address>
            </addresses>
            <phones>
              <phone>
                <type>urn:openhbx:terms:v1:phone_type#home</type>
                <full_phone_number>123322222</full_phone_number>
                <is_preferred></is_preferred>
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
                <type>urn:openhbx:terms:v1:address_type#work</type>
                <address_line_1>12 Downing</address_line_1>
                <address_line_2>23 Taft </address_line_2>
                <location_city_name>Washington </location_city_name>
                <location_state_code>DC</location_state_code>
                <postal_code>12344</postal_code>
              </address>
            </addresses>
            <phones>
              <phone>
                <type>urn:openhbx:terms:v1:phone_type#home</type>
                <full_phone_number>12322222</full_phone_number>
                <is_preferred></is_preferred>
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
      "urn:openhbx:events:v1:employer#contact_changed"
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
      "urn:openhbx:events:v1:employer#contact_changed"
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
                <type>urn:openhbx:terms:v1:address_type#work</type>
                <address_line_1>124 Downing</address_line_1>
                <address_line_2>23 Taft </address_line_2>
                <location_city_name>Washington </location_city_name>
                <location_state_code>DC</location_state_code>
                <postal_code>12344</postal_code>
              </address>
            </addresses>
            <phones>
              <phone>
                <type>urn:openhbx:terms:v1:phone_type#home</type>
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
              <address>
                <type>urn:openhbx:terms:v1:address_type#work</type>
                <address_line_1>12 Downing</address_line_1>
                <address_line_2>23 Taft </address_line_2>
                <location_city_name>Washington </location_city_name>
                <location_state_code>DC</location_state_code>
                <postal_code>12344</postal_code>
              </address>
              <phone>
                <type>urn:openhbx:terms:v1:phone_type#home</type>
                <full_phone_number>123322222</full_phone_number>
                <is_preferred></is_preferred>
              </phone>
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
      :end_date => first_plan_year_end_date,
      :issuer_ids => []
    }
  end

  let(:last_plan_year_values) do
    {
      :employer_id => employer_record_id,
      :start_date => last_plan_year_start_date,
      :end_date => last_plan_year_end_date,
      :issuer_ids => []
    }
  end

  let(:updated_plan_year_values) do
    {
      :start_date =>  Date.new(2017, 4, 1),
      :end_date => Date.new(2018, 3, 31),
      :issuer_ids => ["SOME MONGO ID", "SOME OTHER MONGO ID"]
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
          <addresses>
            <address>
              <type>urn:openhbx:terms:v1:address_type#work</type>
              <address_line_1>123 Downing</address_line_1>
              <address_line_2>23 Taft </address_line_2>
              <location_city_name>Washington </location_city_name>
              <location_state_code>DC</location_state_code>
              <postal_code>12344</postal_code>
            </address>
          </addresses>
          <emails>
            <email>
              <type>urn:openhbx:terms:v1:email_type#work</type>
              <email_address>me@work.com</email_address>
            </email>
          </emails>
          <phones>
            <phone>
              <type>urn:openhbx:terms:v1:phone_type#home</type>
              <full_phone_number>1234567890</full_phone_number>
              <is_preferred>true</is_preferred>
            </phone>
          </phones>
        </contact>
      </contacts>
      <office_locations>
        <office_location>
          <id>
            <id>55fc838254726568cd018d01</id>
          </id>
          <primary>true</primary>
          <name>Work</name>
            <address>
              <type>urn:openhbx:terms:v1:address_type#work</type>
              <address_line_1>12 Downing</address_line_1>
              <address_line_2>23 Taft </address_line_2>
              <location_city_name>Washington </location_city_name>
              <location_state_code>DC</location_state_code>
              <postal_code>12344</postal_code>
            </address>
            <phone>
              <type>urn:openhbx:terms:v1:phone_type#home</type>
              <full_phone_number>123322222</full_phone_number>
              <is_preferred>false</is_preferred>
            </phone>
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
              <type>urn:openhbx:terms:v1:address_type#work</type>
              <address_line_1>12 Downing</address_line_1>
              <address_line_2>23 Taft </address_line_2>
              <location_city_name>Washington </location_city_name>
              <location_state_code>DC</location_state_code>
              <postal_code>12344</postal_code>
            </address>
          </addresses>
          <phones>
            <phone>
              <type></type>
              <full_phone_number></full_phone_number>
              <is_preferred>true</is_preferred>
            </phone>
            <phone>
              <type></type>
              <full_phone_number></full_phone_number>
              <is_preferred></is_preferred>
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
            <person_surname>Fred</person_surname>
            <person_name_suffix_text>Sr.</person_name_suffix_text>
            <person_name_prefix_text> Mr.</person_name_prefix_text>
          </person_name>
        </contact>
        <contact>
          <addresses>
            <address>
              <type>urn:openhbx:terms:v1:address_type#work</type>
              <address_line_1>12 Downing</address_line_1>
              <address_line_2>23 Taft </address_line_2>
              <location_city_name>Washington </location_city_name>
              <location_state_code>DC</location_state_code>
              <postal_code>12344</postal_code>
            </address>
          </addresses>
          <phones>
            <phone>
              <type></type>
              <full_phone_number></full_phone_number>
              <is_preferred></is_preferred>
            </phone>
            <phone>
              <type></type>
              <full_phone_number></full_phone_number>
              <is_preferred></is_preferred>
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
            <address>
              <type>urn:openhbx:terms:v1:address_type#work</type>
              <address_line_1>12 Downing</address_line_1>
              <address_line_2>23 Taft </address_line_2>
              <location_city_name>Washington </location_city_name>
              <location_state_code>DC</location_state_code>
              <postal_code>12344</postal_code>
            </address>
            <phone>
              <type></type>
              <full_phone_number></full_phone_number>
              <is_preferred></is_preferred>
            </phone>
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
          <addresses>
            <address>
              <type>urn:openhbx:terms:v1:address_type#work</type>
              <address_line_1>12 Downing</address_line_1>
              <address_line_2>23 Taft </address_line_2>
              <location_city_name>Washington </location_city_name>
              <location_state_code>DC</location_state_code>
              <postal_code>12344</postal_code>
            </address>
          </addresses>
          <emails>
            <email>
              <type>urn:openhbx:terms:v1:email_type#work</type>
              <email_address>me@work.com</email_address>
            </email>
          </emails>
        </contact>
      </contacts>
      <office_locations>
        <office_location>
          <id>
            <id>55fc838254726568cd018d01</id>
          </id>
          <primary>true</primary>
          <name>Work</name>
          <address>
            <type>urn:openhbx:terms:v1:address_type#work</type>
            <address_line_1>12 Downing</address_line_1>
            <address_line_2>23 Taft </address_line_2>
            <location_city_name>Washington </location_city_name>
            <location_state_code>DC</location_state_code>
            <postal_code>12344</postal_code>
          </address>
            <phone>
              <type>urn:openhbx:terms:v1:phone_type#home</type>
              <full_phone_number>123322222</full_phone_number>
              <is_preferred></is_preferred>
            </phone>
        </office_location>
        <office_location>
          <id>
            <id>55fc838254726568cd018d01</id>
          </id>
          <primary>true</primary>
          <name>Work</name>
          <address>
            <type>urn:openhbx:terms:v1:address_type#work</type>
            <address_line_1>12 Downing</address_line_1>
            <address_line_2>23 Taft </address_line_2>
            <location_city_name>Washington </location_city_name>
            <location_state_code>DC</location_state_code>
            <postal_code>12344</postal_code>
          </address>
            <phone>
              <type>urn:openhbx:terms:v1:phone_type#home</type>
              <full_phone_number>123322222</full_phone_number>
              <is_preferred></is_preferred>
            </phone>
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
  let(:contacts){ [instance_double(EmployerContact) , instance_double(EmployerContact) ]  }
  let(:contact){ instance_double(EmployerContact) }

  before :each do
    allow(employer_record).to receive(:employer_office_locations).and_return([])
    allow(Employer).to receive(:where).with({hbx_id: "EMPLOYER_HBX_ID_STRING"}).and_return(existing_employer_records)
  end
end

describe EmployerEvents::EmployerImporter, "for a new employer, given an employer xml with published plan years" do
  include_context "employer importer shared persistance context"

  let(:existing_employer_records) { [] }
  let(:first_plan_year_record) { instance_double(PlanYear) }
  let(:last_plan_year_record) { instance_double(PlanYear) }
  let(:existing_plan_years) { [] }

  let(:employer_contact) { instance_double(EmployerContact) }
  let(:mock_phone) { instance_double(Phone) }
  let(:mock_address) { instance_double(Address) }
  let(:mock_email) { instance_double(Email) }
  let(:office_location) { instance_double(EmployerOfficeLocation) }

  let(:carrier) {instance_double(Carrier, hbx_carrier_id: "20011",:id=>"SOME MONGO ID")}
  let(:carrier_2) {instance_double(Carrier, hbx_carrier_id: "20012",:id=>"SOME OTHER MONGO ID")}
  let(:matched_plan_year){instance_double(PlanYear, :start_date => Date.new(2017, 4, 1), :end_date => Date.new(2018, 3, 31))}
  let(:matched_plan_years){[matched_plan_year]}

  let(:existing_pyvs){{start_date: Date.new(2017, 4, 1), :end_date=> Date.new(2018, 3, 31), }}
  let(:updated_plan_year) { instance_double(PlanYear, :start_date => Date.new(2017, 4, 1), :end_date => Date.new(2018, 3, 31), :issuer_ids =>["SOME MONGO ID", "SOME OTHER MONGO ID"])}
  let(:updated_pyvs) { { :start_date => Date.new(2017, 4, 1), :end_date => Date.new(2018, 3, 31), :issuer_ids =>["SOME MONGO ID", "SOME OTHER MONGO ID"]}}
  let(:created_pyvs) { { :start_date => last_plan_year_start_date, :end_date => last_plan_year_end_date, :issuer_ids =>["SOME MONGO ID", "SOME OTHER MONGO ID"], :employer_id => employer_record_id}}

  let(:pyvs){[{:start_date => first_plan_year_start_date, :end_date => first_plan_year_end_date,   :issuer_ids => ["1", "2"] }] }
  let(:second_pyvs){[{:start_date => last_plan_year_start_date, :end_date => last_plan_year_end_date,   :issuer_ids => ["1", "2"] }] }


  before :each do
    allow(Employer).to receive(:create!).with(expected_employer_values).and_return(employer_record)
    allow(EmployerContact).to receive(:new).and_return(employer_contact)
    allow(EmployerOfficeLocation).to receive(:new).and_return(office_location)
    allow(employer_record).to receive(:employer_contacts).and_return([])
    allow(employer_record).to receive(:employer_contacts=).and_return([])
    allow(employer_record).to receive(:employer_office_locations).and_return([])
    allow(employer_record).to receive(:save!).and_return(employer_record)
    allow(employer_record).to receive(:employer_office_locations=).and_return(instance_of(Array))
    allow(employer_contact).to receive(:emails).and_return([])
    allow(employer_contact).to receive(:phones).and_return([])
    allow(employer_contact).to receive(:addresses).and_return([])
    allow(employer_contact).to receive(:emails=).and_return([])
    allow(employer_contact).to receive(:phones=).and_return([])
    allow(employer_contact).to receive(:addresses=).and_return([])
    allow(office_location).to receive(:phone).and_return([])
    allow(office_location).to receive(:address).and_return([])
    allow(office_location).to receive(:phone=).and_return([])
    allow(office_location).to receive(:address=).and_return([])

    allow(PlanYear).to receive(:create!).with([first_plan_year_values, last_plan_year_values]).and_return([first_plan_year_record, last_plan_year_record])

    allow(Phone).to receive(:new).and_return(mock_phone)
    allow(Address).to receive(:new).and_return(mock_address)
    allow(Email).to receive(:new).and_return(mock_email)

    allow(Carrier).to receive(:where).with(:hbx_carrier_id => carrier.hbx_carrier_id).and_return([carrier])
    allow(Carrier).to receive(:where).with(:hbx_carrier_id => carrier_2.hbx_carrier_id).and_return([carrier_2])
    allow(matched_plan_year).to receive(:issuer_ids).and_return( ["SOME MONGO ID", "SOME OTHER MONGO ID"])
    allow(employer_record).to receive(:id).and_return(employer_record_id)
    allow(Carrier).to receive(:all).and_return([carrier, carrier_2])
    allow(carrier).to receive(:hbx_carrier_id).and_return('1')
    allow(carrier_2).to receive(:hbx_carrier_id).and_return('2')
  end

  let(:new_contact_email) { instance_double(Email) }
  let(:new_contact_phone) { instance_double(Phone) }
  let(:new_contact_address) { instance_double(Address) }

  let(:new_office_phone) { instance_double(Phone) }
  let(:new_office_address) { instance_double(Address) }

  subject { EmployerEvents::EmployerImporter.new(employer_event_xml, event_name) }

  it 'updates an existing PY' do
    expect(matched_plan_year).to receive(:update_attributes!).with(updated_pyvs) #.and_return(updated_plan_year)
    subject.match_and_persist_plan_years(employer_record_id, pyvs, matched_plan_years)
  end

  it 'creates a new py' do
    expect(PlanYear).to receive(:create!).with([created_pyvs])
    subject.match_and_persist_plan_years(employer_record_id, second_pyvs, matched_plan_years)
  end

  it "persists the employer with the correct attributes" do
    expect(Employer).to receive(:create!).with(expected_employer_values).and_return(employer_record)
    subject.persist
  end

  it "creates new plan years for the employer with the correct attributes" do
    expect(PlanYear).to receive(:create!).with([first_plan_year_values,last_plan_year_values]).and_return([first_plan_year_record, last_plan_year_record])
    subject.persist
  end

  it "creates new office locations" do
    expect(EmployerOfficeLocation).to receive(:new).with(
      {name: "Work", :is_primary=>true}
    ).and_return(office_location)
    subject.persist
  end

  it "creates new office location address" do
    expect(Address).to receive(:new).with(
      {:address_1=>"12 Downing",
       :address_2=>"23 Taft ",
       :city=>"Washington ",
       :state=>"DC",
       :zip=>"12344",
       :address_type=>"work"}
    ).and_return(new_office_address)
    expect(office_location).to receive(:address=).with(new_office_address).and_return(new_office_address)
    subject.persist
  end

  it "creates new office location phone" do
    expect(Phone).to receive(:new).with({
      :phone_number=>"123322222",
      :phone_type=>"home"
    }).and_return(new_office_phone)
    expect(office_location).to receive(:phone=).with(new_office_phone).and_return(new_office_phone)
    subject.persist
  end

  it "creates the new employer contact" do
    expect(EmployerContact).to receive(:new).with(
      {:name_prefix=>" Mr.",
       :first_name=>"Dan",
       :middle_name=>"l",
       :last_name=>"Smith",
       :name_suffix=>"Sr.",
       :job_title=>"rector",
       :department=>"hr"}
    ).and_return(employer_contact)
    subject.persist
  end

  it "creates new contact email" do
    expect(Email).to receive(:new).with(
      {
        email_type: "work",
        email_address: "me@work.com"
      }
    ).and_return(new_contact_email)
    expect(employer_contact).to receive(:emails=).with([new_contact_email]).and_return([new_contact_email])
    subject.persist
  end

  it "creates new contact phone" do
    expect(Phone).to receive(:new).with({
      :phone_number=>"1234567890",
      :phone_type=>"home",
      :primary => true
    }).and_return(new_contact_phone)
    expect(employer_contact).to receive(:phones=).with([new_contact_phone]).and_return([new_contact_phone])
    subject.persist
  end

  it "creates new contact address" do
    expect(Address).to receive(:new).with(
      {:address_1=>"123 Downing",
       :address_2=>"23 Taft ",
       :city=>"Washington ",
       :state=>"DC",
       :zip=>"12344",
       :address_type=>"work"}
    ).and_return(new_contact_address)
    expect(employer_contact).to receive(:addresses=).with([new_contact_address]).and_return([new_contact_address])
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
    allow(employer_record).to receive(:employer_contacts).and_return(contacts)
    allow(employer_record).to receive(:employer_office_locations).and_return([])
    allow(employer_record).to receive(:employer_office_locations=).and_return(instance_of(Array))
    allow(employer_record).to receive(:save!).and_return(employer_record)
    allow(employer_record).to receive(:update_attributes!).with(expected_employer_values).and_return(true)
    allow(PlanYear).to receive(:create!).with([first_plan_year_values, last_plan_year_values]).and_return([first_plan_year_record, last_plan_year_record])
  end

  it "updates the employer with the correct attributes" do
    expect(employer_record).to receive(:update_attributes!).with(expected_employer_values).and_return(true)
    subject.persist
  end

  it "creates new plan years for the employer with the correct attributes" do
    expect(PlanYear).to receive(:create!).with([first_plan_year_values, last_plan_year_values]).and_return([first_plan_year_record, last_plan_year_record])
    subject.persist
  end
end

describe EmployerEvents::EmployerImporter, "for an existing employer with one overlapping plan year, given an employer xml with published plan years" do
  include_context "employer importer shared persistance context"
  let(:carrier) {instance_double(Carrier, hbx_carrier_id: "20011",:id=>"SOME MONGO ID")}
  let(:carrier_2) {instance_double(Carrier, hbx_carrier_id: "20012",:id=>"SOME OTHER MONGO ID")}

  let(:existing_employer_records) { [employer_record] }
  let(:first_plan_year_record) { instance_double(PlanYear, :start_date => first_plan_year_start_date, :end_date => nil, :issuer_ids => []) }
  let(:last_plan_year_record) { instance_double(PlanYear) }
  let(:existing_plan_years) { [first_plan_year_record] }
  let(:updated_plan_year) { instance_double(PlanYear, :start_date => Date.new(2018, 4, 1), :end_date => Date.new(2019, 3, 31), :issuer_ids =>["SOME MONGO ID", "SOME OTHER MONGO ID"])}

  let(:office_location) { instance_double(EmployerOfficeLocation) }
  let(:incoming_office_location) { instance_double(Openhbx::Cv2::OfficeLocation, name:"place", is_primary: true) }

  let(:address_changed_subject) { EmployerEvents::EmployerImporter.new(employer_event_xml_multiple_contacts, address_changed_event_name) }
  let(:contact_changed_subject) { EmployerEvents::EmployerImporter.new(employer_event_xml_multiple_contacts, contact_changed_event_name) }
  let(:contact_changed_event_name) {"urn:openhbx:events:v1:employer#contact_changed"}
  let(:address_changed_event_name) {"urn:openhbx:events:v1:employer#address_changed"}

  subject { EmployerEvents::EmployerImporter.new(employer_event_xml_multiple_contacts, event_name) }

  before :each do
    allow(Carrier).to receive(:all).and_return([carrier, carrier_2])
    allow(Carrier).to receive(:where).with(:hbx_carrier_id => carrier.hbx_carrier_id).and_return([carrier])
    allow(Carrier).to receive(:where).with(:hbx_carrier_id => carrier_2.hbx_carrier_id).and_return([carrier_2])

    allow(contact).to receive(:phones=).and_return(instance_of(Array))

    allow(employer_record).to receive(:update_attributes!).with(expected_employer_values).and_return(true)
    allow(employer_record).to receive(:employer_contacts=).with(instance_of(Array))
    allow(employer_record).to receive(:save!).and_return(employer_record)
    allow(employer_record).to receive(:employer_contacts).and_return(nil)
    allow(employer_record).to receive(:employer_office_locations=).with(instance_of(Array))

    allow(first_plan_year_record).to receive(:update_attributes!).and_return(true)

    allow(PlanYear).to receive(:create!).with([last_plan_year_values]).and_return(last_plan_year_record)
  end

  it "adds every employer contact" do
    subject.persist
    expect(employer_record).to have_received(:employer_contacts=).with(instance_of(Array))
  end

  it "updates the employer with the correct attributes" do
    expect(employer_record).to receive(:update_attributes!).with(expected_employer_values).and_return(true)
    subject.create_or_update_employer
  end

  it "creates only the one new plan year for the employer with the correct attributes" do
    expect(first_plan_year_record).to receive(:update_attributes!).with(updated_plan_year_values).and_return(updated_plan_year)
    subject.persist
  end

  it "adds every employer office location" do
    subject.persist
    expect(employer_record).to have_received(:employer_office_locations=).with(instance_of(Array))
  end

  describe '#is_contact_information_update_event?' do
    let(:address_changed_subject) { EmployerEvents::EmployerImporter.new(employer_event_xml_multiple_contacts, address_changed_event_name) }
    let(:contact_changed_subject) { EmployerEvents::EmployerImporter.new(employer_event_xml_multiple_contacts, contact_changed_event_name) }
    let(:contact_changed_event_name) {"urn:openhbx:events:v1:employer#contact_changed"}
    let(:address_changed_event_name) {"urn:openhbx:events:v1:employer#address_changed"}

    context 'with a non-update event' do
      it 'returns false' do
        expect(subject.is_contact_information_update_event?).to eq false
      end
    end

    context "with a contact changed update event" do
      it 'returns true' do
        expect(contact_changed_subject.is_contact_information_update_event?).to eq true
      end
    end

    context "with an address changed update event" do
      it 'returns true' do
        expect(contact_changed_subject.is_contact_information_update_event?).to eq true
      end
    end
  end

  describe '#extract_office_location_attributes' do
    context 'with an incoming office location' do
      it 'extracts office the location attributes' do
        expect(subject.extract_office_location_attributes(incoming_office_location)).to eq ({name: "place", is_primary: true})
      end
    end
  end

  describe '#strip_type_urn' do
    let(:home_type_urn) { "urn:openhbx:terms:v1:phone_type#home" }
    let(:work_type_urn) { "urn:openhbx:terms:v1:phone_type#work" }

    context 'with an incoming event type urn' do
      it 'strips the event type urn' do
        expect(subject.send(:strip_type_urn, home_type_urn)).to eq ("home")
        expect(subject.send(:strip_type_urn, work_type_urn)).to eq ("work")
      end
    end
  end
end
