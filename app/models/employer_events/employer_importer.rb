module EmployerEvents
  class EmployerImporter
    XML_NS = { "cv" => "http://openhbx.org/api/terms/1.0" }

    attr_reader :xml

    def initialize(employer_xml, event_name)
      @xml = Nokogiri::XML(employer_xml)
      @event_name = event_name.split("#").last
      @org  = Openhbx::Cv2::Organization.parse(@xml, single: true)
      @carrier_id_map = Hash.new
      Carrier.all.each do |car|
        @carrier_id_map[car.hbx_carrier_id] = car.id
      end
    end

    def importable?
      @importable ||= @xml.xpath("//cv:employer_profile/cv:plan_years/cv:plan_year", XML_NS).any?
    end

    def employer_values
     employer_values =
     {
        hbx_id: @org.id,
        fein: @org.fein,
        dba: @org.dba,
        name: @org.name
      }
      employer_values.delete_if{|k,v| v.blank?}
      employer_values
    end

    def manage_employer_demographics(employer)
      if employer.employer_contacts.blank? || is_contact_information_update_event?
        add_contacts(@org.contacts, employer)
      end

      if employer.employer_office_locations.blank? || is_contact_information_update_event?
        add_office_locations(@org.office_locations,employer)
      end
    end

    def is_contact_information_update_event?
      clean_event_name = Maybe.new(@event_name).strip.split("#").last.value
      ["address_changed", "contact_changed"].include?(clean_event_name)
    end

    def add_contacts(incoming_contacts, employer)
      if incoming_contacts.present?
        employer.employer_contacts = incoming_contacts.map do |incoming_contact|
          contact_attributes =
          {
            name_prefix: incoming_contact.name_prefix,
            first_name: incoming_contact.first_name,
            middle_name: incoming_contact.middle_name,
            last_name: incoming_contact.last_name,
            name_suffix: incoming_contact.name_suffix,
            job_title: incoming_contact.job_title,
            department: incoming_contact.department
          }
          contact_attributes.delete_if{|k,v| v.blank?}
          new_contact = EmployerContact.new(contact_attributes)
          add_contacts_phones(incoming_contact.phones, new_contact)
          add_contacts_addresses(incoming_contact.addresses, new_contact)
          add_contacts_emails(incoming_contact.emails, new_contact)
          new_contact
        end
      end
      employer.save!
    end

    def add_contacts_phones(incoming_phones, new_contact)
      new_contact.phones = incoming_phones.map do |incoming_phone|
        new_phone(incoming_phone)
      end
    end

    def add_contacts_emails(incoming_emails, new_contact)
      new_contact.emails = incoming_emails.map do |incoming_email|
        new_email(incoming_email)
      end
    end

    def add_contacts_addresses(incoming_addresses, new_contact)
      new_contact.addresses = incoming_addresses.map  do |incoming_address|
        new_address(incoming_address)
      end
    end

    def extract_office_location_attributes(incoming_office_location)
      ol_attributes = {
        name: incoming_office_location.name,
        is_primary: !!incoming_office_location.is_primary
      }
      ol_attributes.delete_if{|k,v| v.blank?}
    end

    def add_office_locations(incoming_office_locations, employer)
      employer.employer_office_locations = incoming_office_locations.map do |incoming_office_location|
          new_location = EmployerOfficeLocation.new(
            extract_office_location_attributes(incoming_office_location)
          )
          new_location.phone = new_phone(incoming_office_location.phone)
          new_location.address = new_address(incoming_office_location.address)
          new_location
        end
      employer.save!
    end

    def new_email(incoming_email)
      if incoming_email.present?
        email_attributes =
        {
          email_type: strip_type_urn(incoming_email.type),
          email_address: incoming_email.email_address
        }
        email_attributes.delete_if{|k,v| v.blank?}
        Email.new(email_attributes)
      end
    end

    def new_phone(incoming_phone)
      if incoming_phone.present?
        phone_attributes =
        {
          phone_number: incoming_phone.full_phone_number,
          phone_type: strip_type_urn(incoming_phone.type),
          primary: !!incoming_phone.is_preferred
        }
        phone_attributes.delete_if{|k,v| v.blank?}
        Phone.new(phone_attributes)
      end
    end

    def new_address(incoming_address)
      if incoming_address.present?
        address_attributes =
        {
          address_1: incoming_address.address_line_1,
          address_2: incoming_address.address_line_2,
          city: incoming_address.location_city_name,
          state: incoming_address.location_state_code,
          zip: incoming_address.postal_code,
          address_type: strip_type_urn(incoming_address.type)
        }
        address_attributes.delete_if{|k,v| v.blank?}
        Address.new(address_attributes)
      end
    end

    def plan_year_values
      @xml.xpath("//cv:organization/cv:employer_profile/cv:plan_years/cv:plan_year", XML_NS).map do |node|
        py_start_node = node.xpath("cv:plan_year_start", XML_NS).first
        py_end_node = node.xpath("cv:plan_year_end", XML_NS).first
        py_start_date = date_node_value(py_start_node)
        py_end_date = date_node_value(py_end_node)
        carrier_hbx_ids = node.xpath(".//cv:elected_plan/cv:carrier/cv:id/cv:id", XML_NS).map do |id|
          stripped_node_value(id)
        end.compact
        
        {
          :start_date => py_start_date,
          :end_date => py_end_date,
          :issuer_ids => carrier_hbx_ids
        }
      end
    end

    def create_new_plan_years(employer_id, new_pys)
      attributes_with_issuer_ids = new_pys.map do |py|
        issuer_ids = py[:issuer_ids].map do |ihi|
          @carrier_id_map[ihi]
        end.compact
        py.merge(
          :issuer_ids => issuer_ids,
          :employer_id => employer_id
        )
      end
      return nil if attributes_with_issuer_ids.empty?
      PlanYear.create!(attributes_with_issuer_ids)
    end

    def update_matched_plan_years(employer, matched_plan_years)
      matched_plan_years.each do |mpy|
        py_record, py_attributes = mpy
        issuer_ids = py_attributes[:issuer_ids].map do |ihi|
          @carrier_id_map[ihi]
        end.compact
        plan_year_update_data = py_attributes.merge(
          :issuer_ids => issuer_ids,
          )
          # binding.pry
        py_record.update_attributes!(plan_year_update_data)
      end
    end

    def plan_year_loop(pyvs)
      start_date = pyvs[:start_date].strftime("%Y%m%d")
      end_date = pyvs[:end_date].strftime("%Y%m%d")
      @xml.xpath("//cv:plan_year", XML_NS).select do |node|
        stripped_node_value(node.xpath("cv:plan_year_start", XML_NS).first) == start_date &&
        stripped_node_value(node.xpath("cv:plan_year_end", XML_NS).first) == end_date
      end
    end

    def carrier_mongo_ids(pyvs)
      issuer_ids(pyvs).flatten.map do |hbx_carrier_id|
        Carrier.where(hbx_carrier_id: hbx_carrier_id).first.id
      end
    end

    def update_plan_years(pyvs, employer)
      plan_year = employer.plan_years.detect{|py|py.start_date == pyvs[:start_date] && py.end_date == pyvs[:end_date] }
      plan_year.update_attributes!(:issuer_ids => carrier_mongo_ids(pyvs)) if carrier_mongo_ids(pyvs).present?
    end

    def create_or_update_employer
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
      {:employer_id => employer_record.id, :existing_plan_years => employer_record.plan_years}
    end

    def persist
      return unless importable?
      employer = create_or_update_employer
      match_and_persist_plan_years(employer[:employer_id], plan_year_values, employer[:existing_plan_years]) 
    end

    def match_and_persist_plan_years(employer, py_data, existing_plan_years)
      existing_hash = Hash.new
      existing_plan_years.each do |epy|
        existing_hash[epy.start_date] = epy
      end
      py_data_hash = Hash.new
      py_data.each do |pdh|
        py_data_hash[pdh[:start_date]] = pdh
      end
      candidate_new_pys = Array.new
      matched_pys = Array.new
      error_pys = Array.new
      if existing_hash.present? 
        existing_hash.each_pair do |k, v|
          if py_data_hash.has_key?(k)
            matched_pys << [existing_hash[k], py_data_hash.delete(k)]
          end
        end
      else
        candidate_new_pys << py_data
      end
      new_pys = Array.new
      candidate_new_pys.flatten.each do |npy|
        npy_start = npy[:start_date]
        npy_end = npy[:end_date] ? npy[:end_date] : (npy[:start_date] + 1.year - 1.day)
        py_is_bad = existing_plan_years.any? do |epy|
          end_date = epy.end_date ? epy.end_date : (epy.start_date + 1.year - 1.day)
          (npy_start..npy_end).overlaps?((epy.start_date..end_date))
        end
        if py_is_bad
          error_pys << npy
        else
          new_pys << npy
        end
      end
      error_pys.each do |error_py|
        Rails.logger.error "[EmployerEvents::Errors::UpstreamPlanYearOverlap] Upstream plan year overlaps with, but does not match, existing plan years: Employer ID: #{employer.hbx_id}, PY Start: #{npy[:start_date]}, PY End: #{npy[:end_date]}" unless Rails.env.test?
      end
      update_matched_plan_years(employer, matched_pys)
      create_new_plan_years(employer, new_pys)
    end

    protected

    def strip_type_urn(node_content)
      Maybe.new(node_content).strip.split("#").last.value
    end

    def stripped_node_value(node)
      node ? node.content.strip : nil
    end

    def date_node_value(node)
      node ? (Date.strptime(node.content.strip, "%Y%m%d") rescue nil) : nil
    end
  end
end
