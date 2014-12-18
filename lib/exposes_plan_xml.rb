class ExposesPlanXml
  def initialize(parser)
    @parser = parser
  end

  def qhp_id
    @parser.at_xpath('//ns1:qhp_id').text
  end

  def plan_exchange_id
    @parser.at_xpath('//ns1:plan_exchange_id').text
  end

  def carrier_id
    @parser.at_xpath('//ns1:carrier_id').text
  end

  def carrier_name
    @parser.at_xpath('//ns1:carrier_name').text
  end

  def name
    @parser.at_xpath('//ns1:plan_name').text
  end

  def coverage_type
    @parser.at_xpath('//ns1:coverage_type').text
  end

  def original_effective_date
    @parser.at_xpath('//ns1:original_effective_date').text
  end

  def group_id
    node = @parser.at_xpath('//ns1:group_id')
    (node.nil?) ? nil : node.text
  end

  def metal_level_code
    @parser.at_xpath('//ns1:metal_level_code').text
  end

  def policy_number
    node = @parser.at_xpath('//ns1:policy_number')
    (node.nil?) ? '' : node.text
  end
end
