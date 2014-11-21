module Parsers::Xml::Cv
  class ApplicationGroup
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"

    tag 'application_group'

    namespace 'cv'

    element :primary_applicant_id, String, xpath: "cv:primary_applicant_id/cv:id"

    element :submitted_date, String, :tag=> "submitted_date"

    element :e_case_id, String, xpath: "cv:id/cv:id"

    has_many :applicants, Parsers::Xml::Cv::ApplicantParser, :tag => 'applicants'

    has_many :person_relationships, Parsers::Xml::Cv::PersonRelationshipParser, :tag => 'person_relationships'

    element :tax_households, Parsers::Xml::Cv::TaxHouseholdParser, tag:'tax_households'

=begin
    def initialize(parser)
      @parser = parser
    end

    def at_xpath(node, xpath)
      node.at_xpath(xpath, NAMESPACES)
    end

    def primary_applicant_id
      node = @parser.at_xpath('./ns1:primary_applicant_id', NAMESPACES)
      (node.nil?)? nil : node.text
    end
    
    def consent_applicant_id
      node = @parser.at_xpath('./ns1:consent_applicant_id', NAMESPACES)
      (node.nil?)? nil : node.text
    end

    def e_case_id
      node = @parser.at_xpath('./ns1:e_case_id', NAMESPACES)
      (node.nil?)? nil : node.text
    end

    def submitted_date
      node = at_xpath(@parser, './ns1:submitted_date')
      (node.nil?)? nil : node.text
    end
    
    def individuals
      results = []

      elements = @parser.xpath('./ns1:applicants/ns1:applicant', NAMESPACES)
      elements.each { |e| results << Parsers::Xml::Cv::Individual.new(e) }
      results.reject(&:empty?)
    end

    def relationships
      individuals.flat_map { |ind| ind.relationships.reject(&:empty?).map(&:to_request) }
    end

    def consent_applicant_name
      node = @parser.at_xpath('./ns1:consent_applicant_name', NAMESPACES)
      (node.nil?)? nil : node.text
    end

    def consent_renewal_year
      node = @parser.at_xpath('./ns1:consent_renewal_year', NAMESPACES)
      (node.nil?)? 0 : node.text.to_i
    end

    def coverage_renewal_year
      node = @parser.at_xpath('./ns1:coverage_renewal_year', NAMESPACES)
      (node.nil?)? nil : node.text
    end

    def to_request
      {
        consent_applicant_id: consent_applicant_id,
        e_case_id: e_case_id,
        primary_applicant_id: primary_applicant_id,
        submission_date: submitted_date,
        consent_applicant_name: consent_applicant_name,
        consent_renewal_year: consent_renewal_year,
        coverage_renewal_year: coverage_renewal_year,
        people: individuals.map(&:to_request),
        relationships: relationships
      }
    end
=end
  end
end
