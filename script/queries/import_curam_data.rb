the_xml = File.open("RenewalReports.XML")
datas = Nokogiri::XML(the_xml)
nodes = datas.xpath("ns1:application_groups/ns1:application_group", {ns1: 'http://openhbx.org/api/terms/1.0'})

Person.collection.where.update_all({"$set" => {"financial_statements"=> []}})
Person.collection.where.update_all({"$set" => {"person_relationships"=> []}})
ApplicationGroup.delete_all
puts "Purged....now for the fun!"


pb = ProgressBar.create(
  :title => "Importing",
  :total => nodes.length,
  :format => "%t %a %e |%B| %P%%"
)

nodes.each do |node|
  parser = Parsers::Xml::Cv::ApplicationGroup.new(node)
  req = parser.to_request
  cd_importer = ImportCuramData.new
  cd_importer.execute(req)
  pb.increment
end
pb.finish
