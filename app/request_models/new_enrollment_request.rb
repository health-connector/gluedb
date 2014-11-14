class NewEnrollmentRequest
  def self.from_xml(payload=nil)
    # payload = File.open(Rails.root.to_s + "/sample-3.xml")
    xml = Nokogiri::XML(payload)
    enrollment = Parsers::Xml::Reports::NewEnrollment.new(xml.root)

    {
      type: enrollment.type,
      market: enrollment.market,
      people: enrollment.people,
      policies: enrollment.policies
    }
  end
end
