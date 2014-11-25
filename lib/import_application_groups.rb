class ImportApplicationGroups

  def initialize(f_path)
    @file_path = f_path
  end

  def run
    xml = Nokogiri::XML(File.open(@file_path))
    ags = Parsers::Xml::Cv::ApplicationGroup.parse(xml.root.canonicalize)
    ags.each do |ag|
      puts ag.individual_requests
    end
  end

end
