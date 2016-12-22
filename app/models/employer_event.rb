class EmployerEvent
  include Mongoid::Document
  include Mongoid::Timestamps

  field :event_time, type: Time
  field :event_name, type: String
  field :resource_body, type: String
  field :employer_id, type: String

  XML_NS = "http://openhbx.org/api/terms/1.0"

  index({event_time: 1, event_name: 1, employer_id: 1})

  def self.newest_event?(new_employer_id, new_event_name, new_event_time)
    !self.where(:employer_id => new_employer_id, :event_name => new_event_name, :event_time => {"$gte" => new_event_time}).any?
  end

  def self.store_and_yield_deleted(new_employer_id, new_event_name, new_event_time, new_payload)
    new_event = self.create!({
      employer_id: new_employer_id,
      event_name: new_event_name,
      event_time: new_event_time,
      resource_body: new_payload
    })
    self.where(:employer_id => new_employer_id, :event_name => new_event_name, :_id => {"$ne" => new_event._id}).each do |old_record|
      yield old_record
      old_record.destroy
    end
  end

  def has_data_for?(carrier)
    doc = Nokogiri::XML(resource_body)

    doc.xpath("//cv:elected_plans/cv:elected_plan/cv:carrier/cv:id/cv:id[contains(., '#{carrier.hbx_carrier_id}')]", {:cv => XML_NS}).any?
  end

  def self.get_digest_for(carrier)
    events = self.order_by(event_time: 1)
    events_for_carrier = events.select do |ev|
      ev.has_data_for?(carrier)
    end
    return nil unless events_for_carrier.any?
    render_set(carrier, events_for_carrier)
  end

  def self.render_set(carrier, event_set)
    sorted_events = event_set.sort_by(&:event_time)
    first_event_time = sorted_events.first.event_time
    last_event_time = sorted_events.last.event_time
    carrier_abbrev = carrier.abbrev.upcase
    header = <<-XMLHEADER
<?xml version="1.0" encoding="UTF-8"?>
<employer_digest_event
        xmlns="http://openhbx.org/api/terms/1.0"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://openhbx.org/api/terms/1.0 organization.xsd">
        <event_name>urn:openhbx:events:v1:employer#digest_period_ended</event_name>
        <resource_instance_uri>
                <id>urn:openhbx:resources:v1:carrier:abbreviation##{carrier_abbrev}</id>
        </resource_instance_uri>
        <body>
                <employer_events>
                        <coverage_period>
                                <begin_datetime>#{first_event_time.iso8601}</begin_datetime>
                                <end_datetime>#{last_event_time.iso8601}</end_datetime>
                        </coverage_period>
    XMLHEADER
    trailer = <<-XMLTRAILER
                </employer_events>
        </body>
</employer_digest_event>
    XMLTRAILER
    xml_result = header.dup
    sorted_events.each do |ev|
      EmployerEvents::Renderer.new(ev).render_for(carrier, xml_result)
      xml_result << "\n"
    end
    xml_result << trailer
    xml_result
  end

end
