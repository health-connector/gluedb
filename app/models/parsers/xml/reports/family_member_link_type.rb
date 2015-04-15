module Parsers::Xml::Reports
  class ApplicantLinkType

    def initialize(applicant)
      @applicant = applicant
    end

    def policies
      @applicant.xpath("n1:hbx_roles/n1:qhp_roles/n1:qhp_role/n1:policies/n1:policy")
    end

    def qhp_quotes
      @applicant.xpath("n1:hbx_roles/n1:qhp_roles/n1:qhp_role/n1:qhp_quotes/n1:qhp_quote")
    end

    def person_id
      @applicant.at_xpath("n1:person/n1:id").text
    end
  end
end