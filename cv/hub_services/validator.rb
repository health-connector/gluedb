require 'nokogiri'
xsd_path='/Users/CitadelFirm/Downloads/projects/hbx/cv/vocabulary.xsd'
doc_path='/Users/CitadelFirm/Downloads/projects/hbx/enroll/spec/test_data/lawful_presence_payloads/response2.xml'

xsd = Nokogiri::XML::Schema(File.open(xsd_path))
doc = Nokogiri::XML(File.open(doc_path))

xsd.validate(doc).each do |error|
  puts error.message
end