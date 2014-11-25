module Parsers::Xml::Cv

  class PersonDemographicsParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'person_demographics'
    namespace 'cv'

    element :ssn, String, tag: "ssn"
    element :sex, String, tag: "sex"
    element :birth_date, String, tag: "birth_date"
    element :marital_status, String, tag: "marital_status"
    element :citizen_status, String, tag: "citizen_status"
    element :is_state_resident, String, tag: "is_state_resident"


    def individual_request
      {
          :dob => birth_date,
          :ssn => ssn,
          :gender => sex.split("#").last
      }
    end
  end
end