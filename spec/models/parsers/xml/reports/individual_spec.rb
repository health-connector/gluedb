require 'rails_helper'
# require './app/models/parsers/xml/reports/individual'

module Parsers::Xml::Reports
  describe Individual do

    let(:namespace) { 'http://openhbx.org/api/terms/1.0' }
    let(:individual_xml) { "<n1:individual xmlns:n1=\"#{namespace}\">
      <n1:id>#{person_id}</n1:id>
      <n1:application_group_id>#{application_group_id}</n1:application_group_id>
      #{person}
    #{person_demographics}
    #{person_relationships}
    #{financial_reports}
    #{person_health}
      </n1:individual>"
    }

    let(:person_id) { '32231423121' }
    let(:application_group_id) { '331134134113434353' }

    let(:person) {
      "<n1:person>
      <n1:id>2321232323</n1:id>
      <n1:person_name>
      <n1:person_surname>SUR NAME</n1:person_surname>
      <n1:person_given_name>GIVEN NAME</n1:person_given_name>
      <n1:person_middle_name>MIDDLE NAME</n1:person_middle_name>
      <n1:person_full_name>FULL NAME</n1:person_full_name>
      </n1:person_name>
      <n1:job_title>Job Title</n1:job_title>
      <n1:department>Department</n1:department>
      <n1:addresses>
      <n1:address>
      <n1:address_line_1>ADDRESS LINE 1</n1:address_line_1>
      <n1:address_line_2>ADDRESS LINE 2</n1:address_line_2>
      <n1:address_line_3>ADDRESS LINE 3</n1:address_line_3>
      </n1:address>
      </n1:addresses>
      <n1:emails>
      <n1:email>
      <n1:type>work</n1:type>
      <n1:email_address>raghuram@dc.gov</n1:email_address>
      </n1:email>
      </n1:emails>
      </n1:person>"
    }

    let(:person_demographics) {
      "<n1:person_demographics>
      <n1:ssn>8QE332323</n1:ssn>
      <n1:sex>MALE</n1:sex>
      <n1:birth_date>1-1-1998</n1:birth_date>
      <n1:death_date></n1:death_date>
      <n1:is_incarcerated>false</n1:is_incarcerated>
      <n1:language_code>EN</n1:language_code>
      <n1:ethnicity>EQ</n1:ethnicity>
      <n1:race>INDIAN</n1:race>
      <n1:birth_location>DC</n1:birth_location>
      <n1:marital_status>Married</n1:marital_status>
      <n1:citizen_status>US citizen</n1:citizen_status>
      <n1:is_state_resident>Yes</n1:is_state_resident>
      </n1:person_demographics>"
    }

    let(:person_relationships) {
      "<n1:person_relationships>
      <n1:person_relationship>
      <n1:subject_individual>3434223232322323</n1:subject_individual>
      <n1:relationship_uri>spouse</n1:relationship_uri>
      <n1:inverse_relationship_uri></n1:inverse_relationship_uri>
      <n1:object_individual>2231231244123122</n1:object_individual>
      </n1:person_relationship>
      </n1:person_relationships>"
    }

    let(:financial_reports) {
      "<n1:financial_reports>
      <n1:financial_report>
      <n1:tax_filing_status>Joint</n1:tax_filing_status>
      <n1:incomes>
      <n1:income><n1:amount>10000</n1:amount><n1:type>xxx</n1:type></n1:income>
      <n1:income><n1:amount>20000</n1:amount><n1:type>yyy</n1:type></n1:income>
      </n1:incomes>
      </n1:financial_report>
      </n1:financial_reports>"
    }

    let(:person_health) {
      "<n1:person_health>
       <n1:is_tobacco_user>true</n1:is_tobacco_user>
       <n1:is_disabled>false</n1:is_disabled>
       </n1:person_health>"
    }

    skip "is skipped" do

      it 'should parse top level elements' do
        individual = Nokogiri::XML(individual_xml)
        subject = Individual.new(individual.root)
        subject.root_level_elements
        expect(subject.root_elements.id).to eq person_id
        expect(subject.root_elements.application_group_id).to eq application_group_id
      end

      it 'should parse person details' do
        individual = Nokogiri::XML(individual_xml)
        subject = Individual.new(individual.root)
        subject.person_details

        person_name = individual.root.at_xpath('n1:person/n1:person_name')
        expect(subject.person_details.person_name).to eq OpenStruct.new(build_element_hash(person_name))

        addresses = individual.root.xpath('n1:person/n1:addresses/n1:address')
        address_arr = addresses.inject([]) { |data, address| data << OpenStruct.new(build_element_hash(address)) }
        expect(subject.person_details.addresses).to eq address_arr

        emails = individual.root.xpath('n1:person/n1:emails/n1:email')
        email_arr = emails.inject([]) { |data, email| data << OpenStruct.new(build_element_hash(email)) }
        expect(subject.person_details.emails).to eq email_arr
      end

      it 'should parse demograpics data' do
        individual = Nokogiri::XML(individual_xml)
        subject = Individual.new(individual.root)
        subject.person_demographics
        demographics = individual.root.at_xpath('n1:person_demographics')
        expect(subject.demographics).to eq OpenStruct.new(build_element_hash(demographics))
      end

      it 'should parse financial reports' do
        individual = Nokogiri::XML(individual_xml)
        subject = Individual.new(individual.root)
        subject.person_financial_reports
        financial_reports = individual.root.xpath("n1:financial_reports/n1:financial_report")
        financials = financial_reports.inject([]) do |data, report|
          ele_hash = report.elements.inject({}) do |data, node|
            data[node.name.to_sym] = node.elements.count.zero? ? node.text().strip() :
                node.elements.inject([]) { |data, node| data << OpenStruct.new(build_element_hash(node)) }
            data
          end
          data << OpenStruct.new(ele_hash)
        end
        expect(subject.financial_reports).to eq financials
      end

      it 'should parse relationships' do
        individual = Nokogiri::XML(individual_xml)
        subject = Individual.new(individual.root)
        subject.person_relationships
        relationships = individual.root.xpath('n1:person_relationships/n1:person_relationship')
        relationship_arr = relationships.inject([]) { |data, node| data << OpenStruct.new(build_element_hash(node)) }
        expect(subject.relationships).to eq relationship_arr
      end

      it 'should parse health' do
        individual = Nokogiri::XML(individual_xml)
        subject = Individual.new(individual.root)
        subject.person_health
        person_health = individual.root.at_xpath('n1:person_health')
        expect(subject.health).to eq OpenStruct.new(build_element_hash(person_health))
      end
    end

    # it 'should return date of birth' do
    # end

    # it 'should return age' do
    # end

    # it 'should return incarcerated status' do
    # end

    # it 'should return residency status' do
    # end

    # it 'should return citizenship status' do
    # end

    # it 'should return tax status' do
    # end

    private

    def build_element_hash(node)
      node.elements.inject({}) do |data, node|
        data[node.name.to_sym] = node.text().strip()
        data
      end
    end
  end
end