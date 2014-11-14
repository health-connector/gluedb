class NewEnrollmentRequest
  def self.from_xml(payload)

    xml = Nokogiri::XML(payload)

    enrollment = Parsers::Xml::Reports::NewEnrollment.new(xml.root)

    {
      people: enrollment.people,
      policies: enrollment.policies
    }
  end
end
