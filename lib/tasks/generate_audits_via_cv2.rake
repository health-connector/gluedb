require File.join(Rails.root,"script","transform_edi_files.rb")

namespace :carrier_audits do 


end




Dir.mkdir("transformed_audits")
Dir.mkdir("untransformed_audits")

out_path = "transformed_audits"
in_path = "untransformed_audits"

transformer = TransformSimpleEdiFileSet.new(out_path)

dir_glob = Dir.glob(File.join(in_path, "*.xml"))

error_file = File.new('error_file.sh','w')

dir_glob.each do |f|
  begin
    transformer.transform(f)
  rescue Exception => e
    puts "#{f} - #{e.inspect}"
    error_file.puts("mv #{f} failed_transforms/")
  end
end