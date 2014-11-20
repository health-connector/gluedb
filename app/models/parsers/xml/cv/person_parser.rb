module Parsers::Xml::Cv
  class PersonParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'applicant'
    namespace 'cv'

    element :name_first, String,  xpath: "cv:applicant/cv:person/cv:person_name/cv:person_given_name"

    element :name_last, String, xpath: "cv:applicant/cv:person/cv:person_name/cv:person_surname"

    element :name_full, String, xpath: "cv:applicant/cv:person/cv:person_name/cv:person_full_name"

    element :id, String, xpath: "cv:applicant/cv:person/cv:id", :on_save => lambda {|id| id.gsub(/\n/,"").rstrip }

  end
end