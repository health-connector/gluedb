module RemoteResources
  class PersonDemographics
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'person_demographics'
    namespace 'cv'

    element :ssn, String,  tag: "ssn"
    element :birth_date, String,  tag: "birth_date"
    element :sex, String,  tag: "sex"

    def dob
      (birth_date.nil? ? nil : Date.parse(birth_date, "%Y%m%d")) rescue nil
    end

    def gender
      return "unknown" if sex.blank?
      sex.to_s.split("#").last.downcase
    end
  end
end
