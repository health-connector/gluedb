class ExposesPlanXml
  def initialize(parser)
    @parser = parser
  end

  def qhp_id
    @parser.at_xpath('ns1:qhp_id',namespaces).text
  end

  def plan_exchange_id
    @parser.at_xpath('ns1:plan_exchange_id',namespaces).text
  end

  def carrier_id
    @parser.at_xpath('ns1:carrier_id',namespaces).text
  end

  def carrier_name
    @parser.at_xpath('ns1:carrier_name',namespaces).text
  end

  def name
    @parser.at_xpath('ns1:plan_name',namespaces).text
  end

  def coverage_type
    @parser.at_xpath('ns1:coverage_type',namespaces).text
  end

  def original_effective_date
    @parser.at_xpath('ns1:original_effective_date',namespaces).text
  end

  def group_id
    node = @parser.at_xpath('ns1:group_id',namespaces)
    (node.nil?) ? nil : node.text
  end

  def metal_level_code
    @parser.at_xpath('ns1:metal_level_code',namespaces).text
  end

  def policy_number
    node = @parser.at_xpath('ns1:policy_number',namespaces)
    (node.nil?) ? '' : node.text
  end

  def namespaces
    { :ns1 => "http://dchealthlink.com/vocabulary/20131030/employer" }
  end
end
