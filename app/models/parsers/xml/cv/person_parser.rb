module Parsers::Xml::Cv
  class PersonParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'person'
    namespace 'cv'

    element :name_first, String,  tag: "person_name/cv:person_given_name"

    element :name_last, String, tag: "person_name/cv:person_surname"

    element :name_full, String, tag: "person_name/cv:person_full_name"

    element :id, String, tag: "id/cv:id", :on_save => lambda {|id| id.gsub(/\n/,"").rstrip }

    has_many :addresses, Parsers::Xml::Cv::AddressParser, xpath: "cv:addresses"

    has_many :emails, String, xpath: "cv:email"

    has_many :phones, String, xpath: "cv:phones"

    def hbx_member_id
      return nil unless id_is_for_member?
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

    def individual_request
      {
        :name_first => name_first,
        :name_last => name_last,
        :name_middle => name_middle,
        :name_pfx => name_pfx,
        :name_sfx => name_sfx,
        :hbx_member_id => hbx_member_id
      }
    end

  end
end
