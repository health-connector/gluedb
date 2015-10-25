module RemoteResources
  class IndividualResource

    def self.retrieve(requestable, individual_id)
      di, rprops, resp_body = [nil, nil, nil]
      begin
        di, rprops, resp_body = requestable.request({:headers => {:individual_id => individual_id.to_s}, :routing_key => "resource.individual"},"", 15)
        r_headers = (rprops.headers || {}).to_hash.stringify_keys
        r_code = r_headers['return_status'].to_s
        if r_code == "200"
          [r_code, resp_body]    
        else
          [r_code, resp_body.to_s]
        end
      rescue Timeout::Error => e
        ["503", ""]
      end
    end
  end
end
