require './lib/exposes_plan_xml'
require './lib/exposes_contact_xml'
require './lib/null_exposes_contact_xml'


class ExposesEmployerXml
  def initialize(parser)
    @parser = parser
  end

  def name
    @parser.at_xpath('ns1:name', namespaces).text
  end

  def fein
    @parser.at_xpath('ns1:fein', namespaces).text
  end

  def employer_exchange_id
    @parser.at_xpath('ns1:employer_exchange_id', namespaces).text
  end

  def sic_code
    node = @parser.at_xpath('ns1:sic_code', namespaces)
    (node.nil?)? '' : node.text
  end

  def fte_count
    @parser.at_xpath('ns1:fte_count', namespaces).text
  end

  def pte_count
    @parser.at_xpath('ns1:pte_count', namespaces).text
  end

  def broker_npn_id
    node = @parser.at_xpath('ns1:broker/ns1:npn_id', namespaces)
    (node.nil?)? '' : node.text
  end

  def open_enrollment_start
    @parser.at_xpath('ns1:open_enrollment_start', namespaces).text
  end

  def open_enrollment_end
    @parser.at_xpath('ns1:open_enrollment_end', namespaces).text
  end

  def plan_year_start
    @parser.at_xpath('ns1:plan_year_start', namespaces).text
  end

  def plan_year_end
    node = @parser.at_xpath('ns1:plan_year_end', namespaces)
    (node.nil?)? '' : node.text
  end

  def plans
    result = []
    @parser.xpath('ns1:plans/ns1:plan', namespaces).each do |plan_xml|
      result << ExposesPlanXml.new(plan_xml)
    end
    result
  end

  def exchange_id
    @parser.at_xpath('ns1:exchange_id', namespaces).text
  end

  def exchange_status
    @parser.at_xpath('ns1:exchange_status', namespaces).text
  end

  def exchange_version
    @parser.at_xpath('ns1:exchange_version', namespaces).text
  end

  def notes
    node = @parser.at_xpath('ns1:notes', namespaces)
    (node.nil?) ? '' : node.text
  end

  def contact
    namespace = determine_vcard_namespace
    node = @parser.at_css('ns2|vcard', ns2: namespace )
    if(node.nil?)
      NullExposesContactXml.new
    else
      ExposesContactXml.new(node, namespace)
    end
  end

  def namespaces
    { :ns1 => "http://dchealthlink.com/vocabulary/20131030/employer" }
  end

  private

  def determine_vcard_namespace
    possible_namespaces = [
      'urn:ietf:params:xml:ns:vcard-4.0',
      'http://dchealthlink.com/vocabulary/20131030/employer'
    ]

    possible_namespaces.each do |ns|
      node = @parser.at_css('ns2|vcard', ns2: ns)
      return ns if !node.nil?
    end

    ''
  end
end
