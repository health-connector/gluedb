module EmployerEvents
  class EmployerImporter
    XML_NS = { "cv" => "http://openhbx.org/api/terms/1.0" }

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

    def plan_year_loop(pyvs)
      start_date = pyvs[:start_date].strftime("%Y%m%d")
      end_date = pyvs[:end_date].strftime("%Y%m%d")
      @xml.xpath("//cv:plan_year", XML_NS).select do |node|
        stripped_node_value(node.xpath("cv:plan_year_start", XML_NS).first) == start_date && 
        stripped_node_value(node.xpath("cv:plan_year_end", XML_NS).first) == end_date
      end
    end

    def issuer_ids(pyvs)
      plan_year_loop(pyvs).map do |outer_node|
        outer_node.xpath("cv:benefit_groups", XML_NS).map do |node|
          node.xpath("cv:benefit_group/cv:elected_plans", XML_NS).map do |inner_node|
            ids = inner_node.xpath("cv:elected_plan/cv:carrier/cv:id/cv:id", XML_NS).map do |id|
              stripped_node_value(id)
            end
          return ids.flatten || nil
          end
        end
      end
    end

    def carrier_mongo_ids(pyvs)
      issuer_ids(pyvs).flatten.map do |hbx_carrier_id|
          Carrier.where(hbx_carrier_id: hbx_carrier_id).first.id
        end
    end

    def create_plan_year(pyvs, employer_id)
      pyvs.merge!(:employer_id => employer_id)
      pyvs.merge!(:issuer_ids => carrier_mongo_ids(pyvs)) if carrier_mongo_ids(pyvs).present?
      PlanYear.create!(pyvs)
    end

    def update_plan_years(pyvs, employer)
      plan_year = employer.plan_years.detect{|py|py.start_date == pyvs[:start_date] && py.end_date == pyvs[:end_date] } 
      plan_year.update_attributes!(:issuer_ids => carrier_mongo_ids(pyvs)) if carrier_mongo_ids(pyvs).present?
    end


    def persist
      return unless importable?
      existing_employer = Employer.where({:hbx_id => employer_values[:hbx_id]}).first
      employer_record = if existing_employer
                          existing_employer.update_attributes!(employer_values)
                          existing_employer
                        else
                          Employer.create!(employer_values)
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
        if matching_plan_years
          update_plan_years(pyvs, employer_record)
        else
          create_plan_year(pyvs, employer_id)
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