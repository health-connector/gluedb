module EmployerEvents
  class Renderer
    XML_NS = "http://openhbx.org/api/terms/1.0"

    attr_reader :employer_event
    attr_reader :timestamp

    def initialize(e_event)
      @employer_event = e_event
      @timestamp = e_event.event_time
    end

    def carrier_plan_years(carrier)
      doc = Nokogiri::XML(employer_event.resource_body)
      doc.xpath("//cv:elected_plans/cv:elected_plan/cv:carrier/cv:id/cv:id[text() = '#{carrier.hbx_carrier_id}']/../../../../../../..", {:cv => XML_NS})
    end

    def has_current_or_future_plan_year?(carrier)
      found_plan_year = false
      carrier_plan_years(carrier).each do |node|
        node.xpath("cv:plan_year_start", {:cv => XML_NS}).each do |date_node|
          date_value = Date.strptime(date_node.content, "%Y%m%d") rescue nil
          if date_value
            if date_value >= Date.today
              found_plan_year = true
            end
          end
        end
        node.xpath("cv:plan_year_end", {:cv => XML_NS}).each do |date_node|
          date_value = Date.strptime(date_node.content, "%Y%m%d") rescue nil
          if date_value
            if date_value >= Date.today
              found_plan_year = true
            end
          end
        end
      end
      found_plan_year
    end

    def renewal_and_no_future_plan_year?(carrier)
      return false if employer_event.event_name != EmployerEvents::EventNames::RENEWAL_SUCCESSFUL_EVENT
      found_future_plan_year = false
      carrier_plan_years(carrier).each do |node|
        node.xpath("cv:plan_year_start", {:cv => XML_NS}).each do |date_node|
          date_value = Date.strptime(date_node.content, "%Y%m%d") rescue nil
          if date_value
            if date_value > Date.today
              found_future_plan_year = true
            end
          end
        end
      end
      !found_future_plan_year
    end

    def find_latest_carrier_plan_year_in_event(carrier)
      date_sets = carrier_plan_years(carrier).map do |node|
        start_date_node = node.at_xpath("cv:plan_year_start", {:cv => XML_NS})
        end_date_node = node.at_xpath("cv:plan_year_end", {:cv => XML_NS})
        start_date_value = Date.strptime(start_date_node.content, "%Y%m%d") rescue nil
        end_date_value = Date.strptime(end_date_node.content, "%Y%m%d") rescue nil
        (start_date_value && end_date_value) ? [start_date_value, end_date_value] : nil
      end.compact
      date_sets.sort_by(&:first).last
    end

    def qualifies_to_update_event_name?(carrier, employer_event)
      events = [ EmployerEvents::EventNames::RENEWAL_SUCCESSFUL_EVENT, EmployerEvents::EventNames::FIRST_TIME_EMPLOYER_EVENT_NAME ]
      return false unless employer_event.event_name.in?(events) && carrier.uses_issuer_centric_sponsor_cycles
    end

    def update_event_name(carrier, employer_event)
      return employer_event.event_name unless qualifies_to_update_event_name?(carrier, employer_event) && found_previous_plan_year_for_carrier?(carrier)
      employer = Employer.where(hbx_id: employer_event.employer_id).first
      if employer.nil?
        raise ::EmployerEvents::Errors::EmployerEventEmployerNotFound.new("No employer found for: #{employer_event.employer_id}, Employer Event: #{employer_event.id}")
      end
      most_recent_plan_year_dates = find_latest_carrier_plan_year_in_event(carrier)
      if plan_year_dates.nil?
        raise ::EmployerEvents::Errors::NoCarrierPlanYearsInEvent.new("No plan years found in event for: #{carrier.id}, Employer Event: #{employer_event.id}")
      end
      start_date, end_date = most_recent_plan_year_dates
      plan_year = find_employer_plan_year_by_date(employer, start_date, end_date)
      if has_previous_plan_year_for_carrier?(plan_year, carrier)
        EmployerEvents::EventNames::RENEWAL_SUCCESSFUL_EVENT
      else
        EmployerEvents::EventNames::FIRST_TIME_EMPLOYER_EVENT_NAME
      end
    end

    def has_previous_plan_year_for_carrier?(plan_year, carrier)
      previous_plan_years = PlanYear.where(employer_id: plan_year.id, end_date: (plan_year.start_date - 1.day))
      non_canceled_plan_years = previous_plan_years.reject do |py|
        py.start_date == py.end_date
      end
      return false if non_canceled_plan_years.empty?
      non_canceled_plan_years.sort_by(&:start_date).last.issuer_ids.include?(carrier.id)
    end

    def find_employer_plan_year_by_date(employer, start_date, end_date)
      found_py = PlanYear.where(employer_id: employer.id, start_date: start_date, end_date: end_date).first
      if found_py.nil?
        ::EmployerEvents::Errors::EmployerPlanYearNotFound.new("No plan year found for: #{employer_event.employer_id}, Start: #{start_date}, End: #{end_date}")
      end
      found_py
    end

    def found_previous_plan_year_for_carrier?(carrier)
      found_previous_plan_year = false
      carrier_plan_years(carrier).each do |node|
        node.xpath("cv:plan_year_start", {:cv => XML_NS}).each do |date_node|
          date_value = Date.strptime(date_node.content, "%Y%m%d") rescue nil
          if date_value
            if date_value < Date.today
              found_previous_plan_year = true
            end
          end
        end
      end
      found_previous_plan_year
    end

    def drop_and_has_future_plan_year?(carrier)
      return false if employer_event.event_name != EmployerEvents::EventNames::RENEWAL_CARRIER_CHANGE_EVENT
      found_future_plan_year = false
      carrier_plan_years(carrier).each do |node|
        node.xpath("cv:plan_year_start", {:cv => XML_NS}).each do |date_node|
          date_value = Date.strptime(date_node.content, "%Y%m%d") rescue nil
          if date_value
            if date_value > Date.today
              found_future_plan_year = true
            end
          end
        end
      end
      found_future_plan_year
    end

    def render_for(carrier, out)
      unless ::EmployerEvents::EventNames::EVENT_WHITELIST.include?(@employer_event.event_name)
        return false
      end

      doc = Nokogiri::XML(employer_event.resource_body)

      unless carrier_plan_years(carrier).any?
        return false
      end

      return false unless has_current_or_future_plan_year?(carrier)
      return false if drop_and_has_future_plan_year?(carrier)
      return false if renewal_and_no_future_plan_year?(carrier)

      doc.xpath("//cv:elected_plans/cv:elected_plan", {:cv => XML_NS}).each do |node|
        carrier_id = node.at_xpath("cv:carrier/cv:id/cv:id", {:cv => XML_NS}).content
        if carrier_id != carrier.hbx_carrier_id 
          node.remove
        end
      end
      doc.xpath("//cv:employer_census_families", {:cv => XML_NS}).each do |node|
        node.remove
      end
      doc.xpath("//cv:benefit_group/cv:reference_plan", {:cv => XML_NS}).each do |node|
        node.remove
      end
      doc.xpath("//cv:benefit_group/cv:elected_plans[not(cv:elected_plan)]", {:cv => XML_NS}).each do |node|
        node.remove
      end
      doc.xpath("//cv:broker_agency_profile[not(cv:brokers)]", {:cv => XML_NS}).each do |node|
        node.remove
      end
      doc.xpath("//cv:employer_profile/cv:brokers[not(cv:broker_account)]", {:cv => XML_NS}).each do |node|
        node.remove
      end
      doc.xpath("//cv:benefit_group[not(cv:elected_plans)]", {:cv => XML_NS}).each do |node|
        node.remove
      end
      doc.xpath("//cv:plan_year/cv:benefit_groups[not(cv:benefit_group)]", {:cv => XML_NS}).each do |node|
        node.remove
      end
      doc.xpath("//cv:plan_year[not(cv:benefit_groups)]", {:cv => XML_NS}).each do |node|
        node.remove
      end
      event_header = <<-XMLHEADER
                        <employer_event>
                                <event_name>urn:openhbx:events:v1:employer##{update_event_name(carrier, employer_event)}</event_name>
                                <resource_instance_uri>
                                        <id>urn:openhbx:resource:organization:id##{employer_event.employer_id}</id>
                                </resource_instance_uri>
                                <body>
      XMLHEADER
      event_trailer = <<-XMLTRAILER
                                </body>
                        </employer_event>
      XMLTRAILER
      out << event_header
      out << doc.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::NO_DECLARATION, :indent => 2)
      out << event_trailer
      true
    end
  end
end
