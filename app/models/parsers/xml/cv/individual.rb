module Parsers::Xml::Cv
  class Individual
    include NodeUtils

    CITIZEN_STATUS_MAP = {
      "u.s. citizen" => "us_citizen",
      "alien lawfully present" => "alien_lawfully_present",
      "not lawfully present in the u.s" => "not_lawfully_present_in_us"
    }

    def initialize(parser)
      @parser = parser
    end

    def person
      Parsers::Xml::Cv::Person.new(@parser.at_xpath('./ns1:person', NAMESPACES))
    end

    def is_state_resident
      node = @parser.at_xpath('./ns1:is_state_resident', NAMESPACES)
      (node.nil?)? nil : node.text.downcase == 'true'
    end

    def is_applicant
      node = @parser.at_xpath('./ns1:is_applicant', NAMESPACES)
      (node.nil?)? nil : node.text.downcase == 'true'
    end

    def citizen_status
      node = @parser.at_xpath('./ns1:citizen_status', NAMESPACES)
      (node.nil?)? nil : CITIZEN_STATUS_MAP[node.text.downcase]
    end

    def is_incarcerated
      node = @parser.at_xpath('./ns1:is_incarcerated', NAMESPACES)
      is_inc = (node.nil?)? nil : node.text.downcase
      "incarcerated" == is_inc
    end

    def financial_statements
      results = []
      nodes = @parser.xpath('./ns1:financial_statements/ns1:assistance_eligibility', NAMESPACES)
      nodes.each { |i| results << Parsers::Xml::Cv::FinancialStatement.new(i) }
      results
    end

    def relationships
      results = []
      nodes = @parser.xpath('./ns1:relationships/ns1:relationship', NAMESPACES)
      nodes.each { |i| results << Parsers::Xml::Cv::Relationship.new(i) }
      results
    end

    def id
      @parser.at_xpath('.//ns1:qhp_roles/ns1:qhp_role/ns1:id', NAMESPACES).text.strip
    end

    def member_id
      if id.starts_with?("urn:openhbx:hbx:dc0:dcas:individual#")
        return id.split("#").last
      end
      nil
    end

    # Trey -
    #   "You shouldn't have multiple members under a single person,
    #    at least not in CVs generated from Curam"
    #    -- Famous last words
    def gender
      first_text("./ns1:hbx_roles/ns1:qhp_roles/ns1:qhp_role/ns1:gender").downcase #curam import doesnt use urn
    end

    def dob
      first_date("./ns1:hbx_roles/ns1:qhp_roles/ns1:qhp_role/ns1:dob")
    end

    def ssn
      first_text("./ns1:hbx_roles/ns1:qhp_roles/ns1:qhp_role/ns1:ssn")
    end

    def e_person_id
      first_text("./ns1:hbx_roles/ns1:qhp_roles/ns1:qhp_role/ns1:e_person_id")
    end

    def e_concern_role_id
      first_text("./ns1:hbx_roles/ns1:qhp_roles/ns1:qhp_role/ns1:e_concern_role_id")
    end

    def aceds_id
      first_text("./ns1:hbx_roles/ns1:qhp_roles/ns1:qhp_role/ns1:aceds_id")
    end

    def empty?
      [person.name_last, person.name_first].any?(&:blank?)
    end

    def to_request
      person.to_request.merge({
        :is_incarcerated => is_incarcerated,
        :citizen_status => citizen_status,
        :is_state_resident => is_state_resident,
        :is_applicant => is_applicant,
        :id => id,
        :member_id => member_id,
        :ssn => ssn,
        :dob => dob,
        :gender => gender,
        :e_person_id => e_person_id,
        :e_concern_role_id => e_concern_role_id,
        :aceds_id => aceds_id,
        :financial_statements => financial_statements.map(&:to_request)
      })
    end
  end
end
