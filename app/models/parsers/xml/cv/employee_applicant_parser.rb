module Parsers::Xml::Cv

  class EmployeeApplicantParser

    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"

    namespace 'cv'
    tag 'employee_applicant'


    element :employee_id, String, tag:"employee_id"
    element :employment_status, String, tag:"employment_status"
    element :eligibility_date, String, tag:"eligibility_date"
    element :start_date, String, tag:"start_date"
    element :end_date, String, tag:"end_date"

    def to_hash
      response = {
          employee_id: employee_id,
          status: employment_status.split("#").last,
          eligibility_date: eligibility_date,
          start_date: start_date,
          end_date: end_date
      }

      response
    end

  end
end