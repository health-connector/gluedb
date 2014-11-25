class NewEnrollmentRequest
  def self.from_xml(payload=nil)
    # payload = File.open(Rails.root.to_s + "/sample-3.xml")
    xml = Nokogiri::XML(payload)
    enrollment = Parsers::Cv::NewEnrollment.new(xml)

    enrollment.to_hash
  end
end
