module Parsers::Xml::Reports
  class FamilyMemberLinkType

    def initialize(family_member)
      @family_member = family_member
    end

    def policies
      @family_member.xpath("n1:hbx_roles/n1:qhp_roles/n1:qhp_role/n1:policies/n1:policy")
    end

    def qhp_quotes
      @family_member.xpath("n1:hbx_roles/n1:qhp_roles/n1:qhp_role/n1:qhp_quotes/n1:qhp_quote")
    end

    def person_id
      @family_member.at_xpath("n1:person/n1:id").text
    end
  end
end