module EmployerEvents
  class EmployerImporter
    XML_NS = { "cv" => "http://openhbx.org/api/terms/1.0" }

    attr_reader :xml

    def initialize(employer_xml, event_name)
      @xml = Nokogiri::XML(employer_xml)
      @event_name = event_name.split("#").last
      @org  = Openhbx::Cv2::Organization.parse(@xml, single: true)
    end
    
    def importable?
      @importable ||= @xml.xpath("//cv:employer_profile/cv:plan_years/cv:plan_year", XML_NS).any?  
    end

    def contacts(employer)
      {
       name_pfx: employer.name_pfx,
       name_first: employer.name_first,
       name_middle: employer.name_middle,
       name_last: employer.name_last,
       name_sfx: employer.name_sfx,
       name_full: employer.name_full,
       alternate_name: employer.alternate_name
      }
    end  

    def employer_values
      hbx_id_node = @xml.xpath("//cv:organization/cv:id/cv:id", XML_NS).first
      company_name_node = @xml.xpath("//cv:organization/cv:name", XML_NS).first
      dba_node = @xml.xpath("//cv:organization/cv:dba", XML_NS).first
      fein_node = @xml.xpath("//cv:organization/cv:fein", XML_NS).first
      hbx_id = stripped_node_value(hbx_id_node)
      company_name = stripped_node_value(company_name_node)
      dba = stripped_node_value(dba_node)
      fein = stripped_node_value(fein_node)
      {
        hbx_id: hbx_id,
        fein: fein,
        dba: dba,
        name: company_name
      }
    end

    def add_office_locations(locations, employer)
      if locations.present?
        # employer.cont.clear 
        # employer.phones.clear 
        add_location_details(locations, employer)
      end
    end

    def add_location_details(locations, employer) 
        locations.each do |loc|
          type =  loc.address.type.split("#").last
          address_1 = loc.address.address_line_1
          address_2 = loc.address.address_line_2 
          city =  loc.address.location_city_name 
          location_state_code = loc.address.location_state_code 
          zip = loc.address.postal_code
          full_phone_number = loc.phone.full_phone_number 
          phone_type = loc.phone.type.split('#').last
          # employer.phones << Phone.new(full_phone_number:full_phone_number, phone_type:phone_type)
          # employer.addresses << Address.new(type: type, address_1:address_1,address_2: address_2, city: city,location_state_code: location_state_code,zip: zip)
          employer.save
      end
    end 

    def contacts_phones(phones)
      phones.each do |phone|
      end
    end
    
    def add_contacts(contacts, employer)
      employer.employer_contacts.clear
      contacts.each do |contact|

        binding.pry
        
          employer.employer_contacts <<  EmployerContact.new(
              name_prefix: contact.name_prefix,
              first_name: contact.first_name,
              middle_name: contact.middle_name,
              last_name: contact.last_name,
              name_suffix: contact.name_suffix,
              full_name: contact.full_name,
              alternate_name: contact.alternate_name
            )
           contacts_phones(contacts.phones) 
           contacts_addresses(contacts.addresses) 
      end
    end

    
    def manage_employer_demographics(employer)
      if employer.employer_contacts.blank? || @event_name == "contact_changed"
        add_contacts(@org.contacts, employer)
      end

      if employer.employer_office_locations.  blank? || employer.phones.blank?  ||  @event_name == "address_changed"
        add_office_locations(@org.office_locations,employer)
      end
    end

    def plan_year_values
      @xml.xpath("//cv:organization/cv:employer_profile/cv:plan_years/cv:plan_year", XML_NS).map do |node|
        py_start_node = node.xpath("cv:plan_year_start", XML_NS).first
        py_end_node = node.xpath("cv:plan_year_end", XML_NS).first
        py_start_date = date_node_value(py_start_node)
        py_end_date = date_node_value(py_end_node)
        {
          :start_date => py_start_date,
          :end_date => py_end_date
        }
      end
    end

    def persist
      return unless importable?
      existing_employer = Employer.where({:hbx_id => employer_values[:hbx_id]}).first
      employer_record = if existing_employer
                          existing_employer.update_attributes!(employer_values)
                          manage_employer_demographics(existing_employer)
                          existing_employer
                        else
                          employer = Employer.create!(employer_values)
                          manage_employer_demographics(employer)
                          employer
                        end
      employer_id = employer_record.id
      existing_plan_years = employer_record.plan_years
      plan_year_values.each do |pyvs|
        start_date = pyvs[:start_date]
        end_date = pyvs[:end_date] ? pyvs[:end_date] : (start_date + 1.year - 1.day)
        matching_plan_years = existing_plan_years.any? do |epy|
          epy_start = epy.start_date
          epy_end = epy.end_date ? epy.end_date : (epy.start_date + 1.year - 1.day)
          (epy_start..epy_end).overlaps?((start_date..end_date))
        end 
        if !matching_plan_years
          PlanYear.create!(pyvs.merge(:employer_id => employer_id))
        end
      end
    end

    protected

    def stripped_node_value(node)
      node ? node.content.strip : nil
    end

    def date_node_value(node)
      node ? (Date.strptime(node.content.strip, "%Y%m%d") rescue nil) : nil
    end
  end
end 