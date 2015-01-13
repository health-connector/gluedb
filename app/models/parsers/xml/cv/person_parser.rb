module Parsers::Xml::Cv
  class PersonParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'person'
    namespace 'cv'

    element :name_first, String,  tag: "person_name/cv:person_given_name"

    element :name_last, String, tag: "person_name/cv:person_surname"

    element :name_full, String, tag: "person_name/cv:person_full_name"

    element :name_middle, String, tag: "person_name/cv:person_middle_name"

    element :name_pfx, String, tag: "person_name/cv:person_name_prefix_text"

    element :name_sfx, String, tag: "person_name/cv:person_name_suffix_text"

    element :id, String, tag: "id/cv:id"

    has_many :addresses, Parsers::Xml::Cv::AddressParser, xpath: "cv:addresses"

    has_many :emails, Parsers::Xml::Cv::EmailParser, xpath: "cv:emails"

    has_many :phones, Parsers::Xml::Cv::PhoneParser, xpath: "cv:phones"

    def hbx_member_id
      return person_id_tag unless id_is_for_member?
      Maybe.new(person_id_tag).split("#").last.value
    end

    def person_id
      return nil if id_is_for_member?
      Maybe.new(person_id_tag).split("#").last.value
    end

    def id_is_for_member?
      person_id_tag =~ /dcas:individual/
    end

    def person_id_tag
      self.id.blank? ? "" : self.id 
    end

    def individual_request(member_id_generator)
      {
        :name_first => name_first,
        :name_last => name_last,
        :name_middle => name_middle,
        :name_pfx => name_pfx,
        :name_sfx => name_sfx,
        :hbx_member_id => get_or_generate_member_id(member_id_generator),
        :applicant_id => id
      }
    end

    def get_or_generate_member_id(m_id_gen)
      hbx_member_id.blank? ? m_id_gen.generate_member_id : hbx_member_id
    end

    def address_requests
      addresses.map(&:request_hash)
    end

    def phone_requests
      phones.map(&:request_hash)
    end

    def email_requests
      emails.map(&:request_hash)
    end

    def to_hash
      {
          id: id,
          name_first: name_first,
          name_last: name_last
      }
    end

  end
end
