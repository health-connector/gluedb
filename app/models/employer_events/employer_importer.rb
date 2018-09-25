module EmployerEvents
  class EmployerImporter
    XML_NS = { "cv" => "http://openhbx.org/api/terms/1.0" }
    include HappyMapper

    attr_reader :xml

    def initialize(employer_xml)
      @xml = Nokogiri::XML(employer_xml)
    end

    def importable?
      @importable ||= @xml.xpath("//cv:employer_profile/cv:plan_years/cv:plan_year", XML_NS).any?  
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
    
    def demographic_values 
      type = @xml.xpath("//cv:organization/cv:office_locations//cv:office_location//cv:address//cv:type", XML_NS).first
      address_line_1 =  @xml.xpath("//cv:organization/cv:office_locations//cv:office_location//cv:address//cv:address_line_1", XML_NS).first
      location_city_name =  @xml.xpath("//cv:organization/cv:office_locations//cv:office_location//cv:address//cv:location_city_name", XML_NS).first
      location_state_code =  @xml.xpath("//cv:organization/cv:office_locations//cv:office_location//cv:address//cv:location_state_code", XML_NS).first
      postal_code =  @xml.xpath("//cv:organization/cv:office_locations//cv:office_location//cv:address//cv:postal_code", XML_NS).first
      phone_type =  @xml.xpath("//cv:organization/cv:office_locations//cv:office_location//cv:phone//cv:type", XML_NS).first
      phone_number =  @xml.xpath("//cv:organization/cv:office_locations//cv:office_location//cv:phone//cv:full_phone_number", XML_NS).first

      address_type = stripped_node_value(type).split("#").last
      address_line_1 = stripped_node_value(address_line_1)
      city = stripped_node_value(location_city_name)
      state = stripped_node_value(location_state_code)
      zip = stripped_node_value(postal_code)
      phone_type = stripped_node_value(phone_type).split("#").last
      phone_number = stripped_node_value(phone_number)

      {
        address: {
            address_type: address_type,
            address_1: address_line_1,
            city:city ,
            location_state_code: state,
            zip: zip
        },

        phone: {
          phone_type: phone_type, 
          full_phone_number: phone_number

        }
      }
    end

    def add_employer_demographics(demographic_values, employer)
      employer.addresses << Address.new(demographic_values[:address])
      employer.phones << Phone.new(demographic_values[:phone])
      employer.save 
    end

    def update_employer_demographics(demographic_values, employer)  
      employer.addresses.first.update_attributes!(demographic_values[:address])
      employer.phones.first.update_attributes!(demographic_values[:phone])
      employer.save
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
                          update_employer_demographics(demographic_values, existing_employer)
                          existing_employer
                        else
                          employer = Employer.create!(employer_values)
                          add_employer_demographics(demographic_values, employer)
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