module RemoteResources
  class EnrollmentEventResource
    attr_reader :body

    XML_NS = { "cv" => "http://openhbx.org/api/terms/1.0" }

    def initialize(body)
      @body = body
    end

    def transform_action_to(action_uri)
      event_doc = Nokogiri::XML(@body)
      found_action = false
      event_doc.xpath("//cv:enrollment_event_body/cv:enrollment/cv:type", XML_NS).each do |node|
        found_action = true
        node.content = action_uri
      end
      raise "Could not find enrollment action to correct it" unless found_action
      event_doc.to_xml(:indent => 2)
    end

    def to_s
      @body
    end

    def self.retrieve(requestable, hbx_enrollment_id)
      di, rprops, resp_body = [nil, nil, nil]
      begin
        di, rprops, resp_body = requestable.request({:headers => {:policy_id => hbx_enrollment_id.to_s}, :routing_key => "resource.policy"},"", 15)
        r_headers = (rprops.headers || {}).to_hash.stringify_keys
        r_code = r_headers['return_status'].to_s
        if r_code == "200"
          [r_code, self.new(resp_body)]
        else
          [r_code, resp_body.to_s]
        end
      rescue Timeout::Error => e
        ["503", ""]
      end
    end
  end
end
