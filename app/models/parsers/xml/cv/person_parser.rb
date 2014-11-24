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

    #has_one :addresses, Parsers::Xml::Cv::AddressParser, tag: "addresses" TODO

  end
end