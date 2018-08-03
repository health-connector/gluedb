require File.join(Rails.root, 'script', 'generate_c_v_2_1s.rb')

class GenerateTransforms

  def find_policies(eg_ids)
    policies = Policy.where(:eg_id => {"$in" => eg_ids})
    
  end
  
  def generate_transforms
    system("rm -rf source_xmls > /dev/null")
    # system("rm -rf transformed_x12s > /dev/null")
    # system("rm -rf cv1s > /dev/null")

    Dir.mkdir("source_xmls")
    # Dir.mkdir("transformed_x12s")
    # Dir.mkdir("cv1s")

    cv21s = GenerateCv21s.new(ENV['reason_code']).run
    # transformer_1 = TransformSimpleEdiFileSet.new('transformed_x12s')
    # transformer_1 = TransformSimpleEdiFileSet.new('cv1')


  end
end


# class TransformSimpleEdiFileSet
#   include Handlers::EnrollmentEventXmlHelper

#   XML_NS = { "cv" => "http://openhbx.org/api/terms/1.0" }

#   def initialize(out_path)
#     @out_path = out_path
#   end

#   def transform(file_path)
#     action_xml = File.read(file_path)
#     enrollment_event_cv = enrollment_event_cv_for(action_xml)
#     if is_publishable?(enrollment_event_cv)
#       if @out_path == "transformed_xmls"
#         edi_builder == EdiCodec::X12::BenefitEnrollment.new(action_xml)
#       elsif @out_path = "cv1s"
#         edi_builder = EdiCodec::Cv1::Cv1Builder.new(action_xml)
#       end
#       x12_xml = edi_builder.call.to_xml
#       publish_to_file(enrollment_event_cv, x12_xml)
#     end
#   end

#   def publish_to_file(enrollment_event_cv, x12_payload)
        
#     file_name = determine_file_name(enrollment_event_cv)
#     File.open(File.join(@out_path, file_name), 'w') do |f|
#       f.write(x12_payload)
#     end
#   end

#   def find_carrier_abbreviation(enrollment_event_cv)
#     policy_cv = extract_policy(enrollment_event_cv)
#     hios_id = extract_hios_id(policy_cv)
#     active_year = extract_active_year(policy_cv)
#     found_plan = Plan.where(:hios_plan_id => hios_id, :year => active_year.to_i).first
#     found_plan.carrier.abbrev.upcase
#   end

#   def determine_file_name(enrollment_event_cv)
#     market_identifier = shop_market?(enrollment_event_cv) ? "S" : "I"
#     carrier_identifier = find_carrier_abbreviation(enrollment_event_cv)
#     category_identifier = is_initial?(enrollment_event_cv) ? "_C_E_" : "_C_M_"
#     "834_" + transaction_id(enrollment_event_cv) + "_" + carrier_identifier + category_identifier + market_identifier + "_1.xml"
#   end

#   protected

#   def is_publishable?(enrollment_event_cv)
#     Maybe.new(enrollment_event_cv).event.body.publishable?.value
#   end

#   def is_initial?(enrollment_event_cv)
#     event_name = Maybe.new(enrollment_event_cv).event.body.enrollment.enrollment_type.strip.split("#").last.downcase.value
#     (event_name == "initial")
#   end

#   def routing_key(enrollment_event_cv)
#     is_initial?(enrollment_event_cv) ? "hbx.enrollment_messages" : "hbx.maintenance_messages"
#   end

#   def transaction_id(enrollment_event_cv)
#     Maybe.new(enrollment_event_cv).event.body.transaction_id.strip.value
#   end

#   def shop_market?(enrollment_event_cv)
#     determine_market(enrollment_event_cv) == "shop"
#   end
# end


# if @out_path == 'transformed_x12s'
#   out_path = "transformed_x12s"
# elsif @out_path == 'cv1s'
#   out_path = "cv1s"
# end
  
#   transformer = TransformSimpleEdiFileSet.new(out_path)
#   in_path = "source_xmls"
  

#   dir_glob = Dir.glob(File.join(in_path, "*.xml"))


#   error_file = File.new('error_file.sh','w')

#   dir_glob.each do |f|
#     begin
#       transformer.transform(f)
#     rescue Exception => e
#       puts "#{f} - #{e.backtrace.inspect}"
#       error_file.puts("mv #{f} failed_transforms/")
#     end
  
# end

# class TransformSimpleEdiFileSetX12
#   include ::Handlers::EnrollmentEventXmlHelper

#   XML_NS = { "cv" => "http://openhbx.org/api/terms/1.0" }

#   def initialize(out_path)
#     @out_path = out_path
#   end

#   def transform(xml_string)
#     enrollment_event_xml = Nokogiri::XML(xml_string)
#     edi_builder = EdiCodec::X12::BenefitEnrollment.new(xml_string)
#     x12_xml = edi_builder.call.to_xml
#     publish_to_file(enrollment_event_xml, x12_xml)
#   end

#   def publish_to_file(enrollment_event_xml, x12_payload)
#     file_name = determine_file_name(enrollment_event_xml)
#     File.open(File.join(@out_path, file_name), 'w') do |f|
#       f.write(x12_payload)
#     end
#   end

#   def find_carrier_abbreviation(enrollment_event_xml)
#     hios_id = enrollment_event_xml.xpath("//cv:enrollment/cv:plan/cv:id/cv:id", XML_NS).first.content.strip.split("#").last
#     active_year = enrollment_event_xml.xpath("//cv:enrollment/cv:plan/cv:active_year", XML_NS).first.content.strip
#     found_plan = Caches::CustomCache.lookup(Plan, :cv2_hios_active_year_plan_cache, [active_year.to_i, hios_id]) do
#      Plan.where(:hios_plan_id => hios_id, :year => active_year.to_i).first
#     end
#     found_carrier = Caches::CustomCache.lookup(Carrier, :cv2_carrier_cache, found_plan.carrier_id) { found_plan.carrier } 
#     found_carrier.abbrev.upcase
#   end

#   def determine_file_name(enrollment_event_xml)
#     market_identifier = shop_market?(enrollment_event_xml) ? "S" : "I"
#     carrier_identifier = find_carrier_abbreviation(enrollment_event_xml)
#     category_identifier = "_A_F_"
#     "834_" + transaction_id(enrollment_event_xml) + "_" + carrier_identifier + category_identifier + market_identifier + "_1_x12.xml"
#   end

#   protected

#   def transaction_id(enrollment_event_xml)
#     enrollment_event_xml.xpath("//cv:enrollment_event_body/cv:transaction_id", XML_NS).first.content.strip
#   end

#   def shop_market?(enrollment_event_xml)
#     enrollment_event_xml.xpath("//cv:policy/cv:enrollment/cv:shop_market", XML_NS).any?
#   end
# end

# class TransformSimpleEdiFileSetCv1
#   include ::Handlers::EnrollmentEventXmlHelper

#   XML_NS = { "cv" => "http://openhbx.org/api/terms/1.0" }

#   def initialize(out_path)
#     @out_path = out_path
#   end

#   def transform(xml_string)
#     enrollment_event_xml = Nokogiri::XML(xml_string)
#     edi_builder = EdiCodec::Cv1::Cv1Builder.new(xml_string)
#     x12_xml = edi_builder.call.to_xml
#     publish_to_file(enrollment_event_xml, x12_xml)
#   end

#   def publish_to_file(enrollment_event_xml, x12_payload)
#     file_name = determine_file_name(enrollment_event_xml)
#     File.open(File.join(@out_path, file_name), 'w') do |f|
#       f.write(x12_payload)
#     end
#   end

#   def find_carrier_abbreviation(enrollment_event_xml)
#     hios_id = enrollment_event_xml.xpath("//cv:enrollment/cv:plan/cv:id/cv:id", XML_NS).first.content.strip.split("#").last
#     active_year = enrollment_event_xml.xpath("//cv:enrollment/cv:plan/cv:active_year", XML_NS).first.content.strip
#     found_plan = Caches::CustomCache.lookup(Plan, :cv2_hios_active_year_plan_cache, [active_year.to_i, hios_id]) do
#      Plan.where(:hios_plan_id => hios_id, :year => active_year.to_i).first
#     end
#     found_carrier = Caches::CustomCache.lookup(Carrier, :cv2_carrier_cache, found_plan.carrier_id) { found_plan.carrier } 
#     found_carrier.abbrev.upcase
#   end

#   def determine_file_name(enrollment_event_xml)
#     market_identifier = shop_market?(enrollment_event_xml) ? "S" : "I"
#     carrier_identifier = find_carrier_abbreviation(enrollment_event_xml)
#     category_identifier = "_A_F_"
#     "834_" + transaction_id(enrollment_event_xml) + "_" + carrier_identifier + category_identifier + market_identifier + "_1_cv1.xml"
#   end

#   protected

#   def transaction_id(enrollment_event_xml)
#     enrollment_event_xml.xpath("//cv:enrollment_event_body/cv:transaction_id", XML_NS).first.content.strip
#   end

#   def shop_market?(enrollment_event_xml)
#     enrollment_event_xml.xpath("//cv:policy/cv:enrollment/cv:shop_market", XML_NS).any?
#   end
# end

# trans = GenerateTransforms.new