module EmployerEvents
  class EmployerImporter
    XML_NS = { "cv" => "http://openhbx.org/api/terms/1.0" }

    attr_reader :xml

    def initialize(employer_xml)
      @xml = Nokogiri::XML(employer_xml)
      @carrier_id_map = Hash.new
      Carrier.all.each do |car|
        @carrier_id_map[car.hbx_carrier_id] = car.id
      end
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
        py_record.update_attributes!(plan_year_update_data)
      end
    end

    def create_or_update_employer
      existing_employer = Employer.where({:hbx_id => employer_values[:hbx_id]}).first
      employer_record = if existing_employer
                          existing_employer.update_attributes!(employer_values)
                          existing_employer
                        else
                          Employer.create!(employer_values)
                        end
      {:employer_id => employer_record.id, :existing_plan_years => employer_record.plan_years}
    end

    def persist
      return unless importable?
      employer = create_or_update_employer
      match_and_persist_plan_years(employer[:employer_id], plan_year_values, employer[:existing_plan_years]) 
    end

    def match_and_persist_plan_years(employer_id, py_data, existing_plan_years)
      existing_hash = Hash.new
      existing_plan_years.each do |epy|
        existing_hash[epy.start_date] = epy
      end
      py_data_hash = Hash.new
      py_data.each do |pdh|
        py_data_hash[pdh[:start_date]] = pdh
      end
      matched_pys = Array.new
      error_pys = Array.new
      existing_hash.each_pair do |k, v|
        if py_data_hash.has_key?(k)
          matched_pys << [existing_hash[k], py_data_hash.delete(k)]
        end
      end
      candidate_new_pys = py_data_hash.values
      new_pys = Array.new
      candidate_new_pys.each do |npy|
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
      update_matched_plan_years(employer_id, matched_pys)
      create_new_plan_years(employer_id, new_pys)
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