module EnrollmentAction
  class ActionPublishHelper
    XML_NS = { :cv => "http://openhbx.org/api/terms/1.0" }
    attr_reader :event_xml_doc

    delegate :to_xml, :to => :event_xml_doc

    def initialize(xml_string)
      @event_xml_doc = Nokogiri::XML(xml_string)
    end
      
    def filter_affected_members(affected_member_ids)
      event_xml_doc.xpath("//cv:enrollment_event_body/cv:affected_members/cv:affected_member", XML_NS).each do |node|
        found_matching_id = false
        node.xpath("cv:member/cv:id/cv:id", XML_NS).each do |c_node|
          member_id = Maybe.new(c_node).content.strip.split("#").last.value
          if affected_member_ids.include?(member_id)
            found_matching_id = true
          end
        end
        unless found_matching_id
          node.remove
        end
      end
      event_xml_doc
    end

    def keep_member_ends(member_ids)
      event_xml_doc.xpath("//cv:enrollment_event_body/cv:affected_members/cv:affected_member", XML_NS).each do |node|
        found_matching_id = false
        node.xpath("cv:member/cv:id/cv:id", XML_NS).each do |c_node|
          member_id = Maybe.new(c_node).content.strip.split("#").last.value
          if !member_ids.include?(member_id)
            node.xpath("cv:benefit/cv:end_date", XML_NS).each do |d_node|
              d_node.remove
            end
          end
        end
      end
      event_xml_doc.xpath("//cv:enrollment_event_body/cv:enrollment/cv:policy/cv:enrollees/cv:enrollee", XML_NS).each do |node|
        found_matching_id = false
        node.xpath("cv:member/cv:id/cv:id", XML_NS).each do |c_node|
          member_id = Maybe.new(c_node).content.strip.split("#").last.value
          if !member_ids.include?(member_id)
            node.xpath("cv:benefit/cv:end_date", XML_NS).each do |d_node|
              d_node.remove
            end
          end
        end
      end
      event_xml_doc
    end

    def set_member_starts(member_start_hash)
      event_xml_doc.xpath("//cv:enrollment_event_body/cv:affected_members/cv:affected_member", XML_NS).each do |node|
        found_matching_id = false
        node.xpath("cv:member/cv:id/cv:id", XML_NS).each do |c_node|
          member_id = Maybe.new(c_node).content.strip.split("#").last.value
          if member_start_hash.keys.include?(member_id)
            new_date = member_start_hash[member_id]
            node.xpath("cv:benefit/cv:begin_date", XML_NS).each do |d_node|
              unless new_date.blank?
                d_node.content = new_date.strftime("%Y%m%d")
              end
            end
          end
        end
      end
      event_xml_doc.xpath("//cv:enrollment_event_body/cv:enrollment/cv:policy/cv:enrollees/cv:enrollee", XML_NS).each do |node|
        found_matching_id = false
        node.xpath("cv:member/cv:id/cv:id", XML_NS).each do |c_node|
          member_id = Maybe.new(c_node).content.strip.split("#").last.value
          if member_start_hash.keys.include?(member_id)
            new_date = member_start_hash[member_id]
            node.xpath("cv:benefit/cv:begin_date", XML_NS).each do |d_node|
              unless new_date.blank?
                d_node.content = new_date.strftime("%Y%m%d")
              end
            end
          end
        end
      end
      event_xml_doc
    end

    def set_event_action(event_action_value)
      event_xml_doc.xpath("//cv:enrollment_event_body/cv:enrollment/cv:type", XML_NS).each do |node|
        node.content = event_action_value
      end
      event_xml_doc
    end

    def set_policy_id(policy_id_value)
      event_xml_doc.xpath("//cv:enrollment_event_body/cv:enrollment/cv:policy/cv:id/cv:id", XML_NS).each do |node|
        node.content = policy_id_value
      end
      event_xml_doc
    end
  end
end
