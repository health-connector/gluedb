module Parsers::Xml::Cv
  class IrsGroupParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'irs_group'
    namespace 'cv'

    element :id, String, tag: 'id'
    has_many :tax_households_ids, String, xpath:'cv:tax_households_ids/cv:id'
    has_many :hbx_enrollment_ids, String, xpath: 'cv:hbx_enrollment_ids/cv:id'
    has_many :hbx_enrollment_exemption_ids, String, xpath: 'cv:hbx_enrollment_exemption_ids/cv:hbx_enrollment_exemption_id'

    def to_hash
     response = {
          id: id,
          hbx_enrollment_ids: hbx_enrollment_ids.map do |hbx_enrollment_id|
            hbx_enrollment_id
          end,
          hbx_enrollment_exemption_ids: hbx_enrollment_exemption_ids.map do |hbx_enrollment_exemption_id|
            hbx_enrollment_exemption_id
          end
      }

     response
    end

  end
end