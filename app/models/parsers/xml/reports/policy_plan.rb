module Parsers::Xml::Reports
  class PolicyPlan
    def initialize(parser = nil, namespaces = {})
      @root = parser
      @namespaces = namespaces
    end

    def id
      @root.at_xpath('n1:id', @namespaces).text
    end

    def name
      @root.at_xpath('n1:name', @namespaces).text
    end

    def coverage_type
      @root.at_xpath('n1:coverage_type', @namespaces).text
    end

    def plan_year
      @root.at_xpath('n1:plan_year', @namespaces).text
    end

    def carrier
      @root.at_xpath('n1:carrier', @namespaces).elements.inject({}) do |data, element|
        data[element.name.to_sym] = element.text
        data
      end
    end
  end
end