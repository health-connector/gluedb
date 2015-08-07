require Rails.root.join "app", "models", "premiums", "enrollment_cv_proxy.rb"

class QuoteCvProxy < EnrollmentCvProxy
  include ActiveModel::Validations

  validate :presence_of_essential_data

  def initialize(enrollment_cv)
    @xml_doc = Nokogiri::XML(enrollment_cv)
  end

  def enrollees

    enrollees_list = []
    @member_cache_hash = {}
    enrollee_nodes = @xml_doc.xpath('//ns1:enrollee', NAMESPACES)
    enrollee_nodes.each do |enrollee_node|
      enrolle_parser = Parsers::Cv::Enrollee.new(enrollee_node)
      enrolle_parser_hash = enrolle_parser.to_hash
      enrolle_parser_hash[:m_id] = enrolle_parser.to_hash[:m_id].split("hbx_id=").last if enrolle_parser.to_hash[:m_id].include?('hbx_id=')
      enrollee = Enrollee.new(enrolle_parser_hash)
      enrollees_list << enrollee
      member = Member.new(enrolle_parser_hash[:member])
      @member_cache_hash[enrollee.m_id] = member
    end
    [enrollees_list, @member_cache_hash]
  end

  def policy_pre_amt_tot=(value)
    premium_total_amount_node = Nokogiri::XML::Node.new "premium_total_amount", @xml_doc
    premium_total_amount_node.content = value

    enrollment_node = @xml_doc.xpath('//ns1:enrollment', NAMESPACES).first
    enrollment_node.add_child(premium_total_amount_node)
  end

  def enrollees_pre_amt=(enrollees)
    enrollees_node = @xml_doc.xpath('//ns1:enrollee', NAMESPACES)

    enrollees_and_nodes = enrollees_node.zip enrollees

    enrollees_and_nodes.each do |enrollee_node, enrollee|
      enrollee_node.xpath('ns1:benefit/ns1:premium_amount', NAMESPACES).first.content = enrollee.premium_amount
    end
  end

  def presence_of_essential_data

    if enrollees.first.nil?
      errors.add('enrollees', 'enrollee(s) does not exist or could not be parsed successfully')
    else
      enrollees.first.each do |enrollee|
        member = enrollees.last[enrollee.m_id]
        errors.add('enrollee', 'id does not exist or could not be parsed successfully') if enrollee.m_id.nil?
        errors.add('enrollee', 'does not have person_demographics birth_date or could not be parsed successfully') if member.try(:dob).nil?
        errors.add('enrollee', 'person_relationship relationship_uri does not exist or could not be parsed successfully') if enrollee.rel_code.nil?
        errors.add('enrollee', 'benefit begin_date does not exist or could not be parsed successfully') if enrollee.coverage_start.nil?
      end
    end

    if plan.nil?
      errors.add('plan', 'does not exist or could not be parsed successfully')
    else
      errors.add('plan', 'id does not exist or could not be parsed successfully') if plan.id.nil?
    end
  end

  def response_xml
    @xml_doc.xpath('//ns1:coverage_quote_request', NAMESPACES).each do |node|
      node.name = 'coverage_quote'
    end

    @xml_doc.to_xml
  end
end