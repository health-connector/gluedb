class NewEnrollmentRequest
  def self.from_xml(payload=nil)
    # payload = File.open(Rails.root.to_s + "/sample-3.xml")
    xml = Nokogiri::XML(payload)
    enrollment = Parsers::Xml::Reports::NewEnrollment.new(xml.root)

    person_requests = enrollment.people.inject([]) {|data, person| data << UpdatePersonRequest.from_xml(person)}
    policy_requests = enrollment.policies.inject([]) {|data, policy| data << CreatePolicyRequest.from_xml(policy)}

    {
      individuals: person_requests,
      policies: policy_requests
    }
  end
end
