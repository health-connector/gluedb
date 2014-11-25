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

  end
end