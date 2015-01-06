class EnrollmentCvProxy

  NAMESPACES = { ns1: 'http://openhbx.org/api/terms/1.0'}

  def initialize(enrollment_cv)
    @xml_doc = Nokogiri::XML(enrollment_cv)
  end

  def enrollees
    enrollees_list = []
    enrollee_nodes = @xml_doc.xpath('//ns1:enrollee', NAMESPACES)
    enrollee_nodes.each do |enrollee_node|
      enrolle_parser = Parsers::Cv::Enrollee.new(enrollee_nodes)
      enrolle_parser_hash = enrolle_parser.to_hash
      enrolle_parser_hash[:m_id] = enrolle_parser.to_hash[:m_id].split("hbx_id=").last if enrolle_parser.to_hash[:m_id].include?('hbx_id=')
      enrollee = Enrollee.new(enrolle_parser_hash)
      enrollees_list << enrollee
    end
    enrollees_list
  end


  def policy
    policy_node = @xml_doc.xpath('//ns1:policy', NAMESPACES).first
    policy_hash = Parsers::Cv::NewPolicy.new(policy_node).to_hash
    policy = Policy.new(policy_hash)
    policy.enrollees = enrollees
    policy.plan = plan
    policy
  end

  def plan
    plan_hash = Parsers::Xml::Cv::PlanParser.parse(@xml_doc).first.to_hash
    Plan.find(plan_hash[:id])
  end

  def policy_pre_amt_tot=(value)
    @xml_doc.xpath('//ns1:enrollment/ns1:policy/ns1:enrollment/ns1:premium_total_amount', NAMESPACES).first.content = value
  end

  def policy_tot_res_amt=(value)
    @xml_doc.xpath('//ns1:enrollment/ns1:policy/ns1:enrollment/ns1:total_responsible_amount', NAMESPACES).first.content = value
  end

  def policy_emp_res_amt=(value)
    @xml_doc.xpath('//ns1:enrollment/ns1:policy/ns1:enrollment/ns1:shop_market/ns1:total_employer_responsible_amount', NAMESPACES).first.content = value
  end

  def enrollee_pre_amt=(enrollee)
    enrollees_node = @xml_doc.xpath('//ns1:enrollment/ns1:policy/ns1:enrollees', NAMESPACES).first

    @xml_doc.xpath('//ns1:enrollment/ns1:policy/ns1:enrollees/ns1:enrollee/ns1:benefit/ns1:premium_amount', NAMESPACES).first.content = enrollee.premium_amount
  end

  def to_xml
    @xml_doc.to_xml
  end
end