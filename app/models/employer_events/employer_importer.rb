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

    def manage_employer_demographics(employer)
      if employer.employer_contacts.blank? || @event_name == "contact_changed"
        add_contacts(@org.contacts, employer)
      end

      if employer.employer_office_locations.blank? ||  @event_name == "address_changed"
        add_office_locations(@org.office_locations,employer)
      end
    end

    def add_office_locations(incoming_office_locations, employer)
      employer.employer_office_locations.clear
      incoming_office_locations.each do |incoming_office_location|   
        new_location = EmployerOfficeLocation.new(
          name: incoming_office_location.name
          )
          employer.employer_office_locations << new_location
         add_location_phone(new_location, employer)  
         add_location_address(new_location, employer) 
         employer.save!
      end
    end

    def add_location_phone(incoming_phone, new_location, employer)
      new_phone = Phone.new(
        phone_number:  incoming_phone.full_phone_number.last(7),
        full_phone_number: incoming_phone.full_phone_number,
        phone_type: incoming_phone.type,
        primary: incoming_phone.is_preferred
        )
        new_location.phone = new_phone
        employer.save!
    end

    def new_phone()
    end
    def add_location_address(incoming_location, new_location, employer)
    end



    def add_contacts_phones(incoming_phones, new_contact, employer)
      incoming_phones.each do |incoming_phone|
        new_phone = Phone.new(
          phone_number:  incoming_phone.full_phone_number.last(7),
          full_phone_number: incoming_phone.full_phone_number,
          phone_type: incoming_phone.type,
          primary: incoming_phone.is_preferred
          )
          new_contact.phones << new_phone
          employer.save!
        end
    end

    def add_contacts_addresses(incoming_addresses, new_contact, employer)
      incoming_addresses.each do |incoming_address|
      new_address =  Address.new(
        address_1: incoming_address.address_line_1,
        address_2: incoming_address.address_line_2,
        city: incoming_address.location_city_name,
        state: incoming_address.location_state_code,
        zip: incoming_address.postal_code,
        address_type: incoming_address.type
        )
        new_contact.addresses << new_address 
        employer.save!
      end
    end
    
    def add_contacts(incoming_contacts, employer)
      employer.employer_contacts.clear
      incoming_contacts.each do |incoming_contact|   
          new_contact = EmployerContact.new(
              name_prefix: incoming_contact.name_prefix,
              first_name: incoming_contact.first_name,
              middle_name: incoming_contact.middle_name,
              last_name: incoming_contact.last_name,
              name_suffix: incoming_contact.name_suffix,
              job_title: incoming_contact.job_title,
              department: incoming_contact.department  
            )
            add_contacts_phones(incoming_contact.phones, new_contact, employer)  
            add_contacts_addresses(incoming_contact.addresses, new_contact, employer) 
            employer.employer_contacts << new_contact
           employer.save!
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