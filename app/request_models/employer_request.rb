require 'open-uri'
require 'nokogiri'

class EmployerRequest
  def self.many_from_xml(xml)
    requests = []
    elements = Nokogiri::XML(xml).xpath('//cv:employers/cv:employer', {
      :cv => "http://dchealthlink.com/vocabulary/20131030/employer"                                  
    })
    elements.map { |e| EmployerRequest.from_xml(ExposesEmployerXml.new(e)) }
  end

  def self.from_xml(xml)
    request = { 
      name: xml.name,
      fein: xml.fein,
      hbx_id: xml.employer_exchange_id,
      sic_code: xml.sic_code,
      fte_count: xml.fte_count.to_i,
      pte_count: xml.pte_count.to_i,
      open_enrollment_start: xml.open_enrollment_start,
      open_enrollment_end: xml.open_enrollment_end,
      plan_year_start: xml.plan_year_start,
      plan_year_end: xml.plan_year_end,
      notes: xml.notes,
      contact: {
        name: {
          prefix: xml.contact.prefix,
          first: xml.contact.first_name,
          middle: xml.contact.middle_initial,
          last: xml.contact.last_name,
          suffix: xml.contact.suffix
        },
      },
      broker_npn: xml.broker_npn_id,
      plans: []
    }

    if(!xml.contact.street1.blank?)
      request[:contact][:address] = {
        type: 'work',
        street1: xml.contact.street1,
        street2: xml.contact.street2,
        city: xml.contact.city,
        state: xml.contact.state,
        zip: xml.contact.zip
      }
    end

    if(!xml.contact.phone_number.blank?)
      request[:contact][:phone] = {
        phone_type: 'work',
        phone_number: xml.contact.phone_number.gsub(/[^0-9]/,"")
      }
    end

    if(!xml.contact.email_address.blank?)
      request[:contact][:email] = {
        email_type: xml.contact.email_type.downcase,
        email_address: xml.contact.email_address
      }
    end

    xml.plans.each do |plan_data|
      plan = Plan.find_by_hios_id_and_year(plan_data.qhp_id, Date.parse(request[:plan_year_start]).year)
      if plan.nil?
        raise plan_data.qhp_id.inspect 
      else
        request[:plans] << {
          :carrier_id => plan.carrier_id,
          :qhp_id => plan_data.qhp_id,
          :coverage_type => plan_data.coverage_type,
          :metal_level => plan.metal_level,
          :hbx_plan_id => plan.hbx_plan_id,
          :original_effective_date => plan_data.original_effective_date,
          :plan_name => plan.name,
          :carrier_policy_number => plan_data.policy_number,
          :carrier_employer_group_id => plan_data.group_id
        }
      end
    end
    request
  end
end


        
