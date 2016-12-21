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

  def remove_other_carrier_nodes(xml, carrier_hbx_id)
    doc = Nokogiri::XML(xml)

    data_for_carrier = doc.xpath("//cv:elected_plans/cv:elected_plan/cv:carrier/cv:id/cv:id[contains(., '#{carrier_hbx_id}')]", {:cv => XML_NS}).any?

    doc.xpath("//cv:elected_plans/cv:elected_plan", {:cv => XML_NS}).each do |node|
      carrier_id = node.at_xpath("cv:carrier/cv:id/cv:id", {:cv => XML_NS}).content
      if carrier_id != carrier_hbx_id
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
    doc.xpath("//cv:brokers[not(cv:broker_account)]", {:cv => XML_NS}).each do |node|
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
    doc.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::NO_DECLARATION, :indent => 2)
  end
end
