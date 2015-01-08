class EnrollmentValidator < DocumentValidator

  POLICY_SCHEMA = File.join(Rails.root, 'cv', 'policy.xsd')

  def initialize(xml)
    schema = Nokogiri::XML::Schema(File.open(POLICY_SCHEMA))
    xml_doc = Nokogiri::XML(xml)
    super(xml_doc, schema)
  end

end
