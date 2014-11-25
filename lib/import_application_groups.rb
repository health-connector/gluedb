class ImportApplicationGroups

  def initialize(f_path)
    @file_path = f_path
  end

  def run
    xml = Nokogiri::XML(File.open(@file_path))
    ns = { :cv => "http://openhbx.org/api/terms/1.0"}
    xml.xpath("//cv:application_groups/cv:application_group") do |node| 
      ag = Parsers::Xml::Cv::ApplicationGroup.parse(node.canonicalize, :single => true)
    end
  end

end
