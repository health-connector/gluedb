module RemoteResources
  class IndividualResource
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'individual'
    namespace 'cv'

    element :id, String, tag: "id/cv:id"

    has_one :person, ::RemoteResources::Person, :tag => "person"
    has_one :person_demographics, ::RemoteResources::PersonDemographics, :tag => "person_demographics"

    delegate :name_first, :name_last, :name_middle, :name_sfx, :name_pfx, :to => :person, :allow_nil => true

    delegate :ssn, :dob, :gender, :to => :person_demographics

    def hbx_member_id
      Maybe.new(id).split("#").last.value
    end

    def self.retrieve(requestable, individual_id)
      di, rprops, resp_body = [nil, nil, nil]
      begin
        di, rprops, resp_body = requestable.request({:headers => {:individual_id => individual_id.to_s}, :routing_key => "resource.individual"},"", 15)
        r_headers = (rprops.headers || {}).to_hash.stringify_keys
        r_code = r_headers['return_status'].to_s
        if r_code == "200"
          [r_code, self.parse(resp_body, :single => true)]
        else
          [r_code, resp_body.to_s]
        end
      rescue Timeout::Error => e
        ["503", ""]
      end
    end
  end
end
