module Parsers::Xml::Reports
  class PolicyPlan

    include NodeUtils

    def initialize(parser = nil, namespaces = {})
      @root = parser
      @namespaces = namespaces
    end

    def id
      parse_uri(@root.at_xpath('n1:id', @namespaces).text.strip)
    end

    def name
      @root.at_xpath('n1:name', @namespaces).text.strip
    end

    def coverage_type
      @root.at_xpath('n1:coverage_type', @namespaces).text.strip
    end

    def plan_year
      @root.at_xpath('n1:plan_year', @namespaces).text.strip
    end

    def carrier
      @root.at_xpath('n1:carrier', @namespaces).elements.inject({}) do |data, element|
        data[element.name.to_sym] = element.text.strip
        data
      end
    end
  end
end