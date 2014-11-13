module Parsers::Xml::Reports
  class PolicyPlan
    def initialize(parser = nil)
      @root = parser
    end

    def id
      @root.at_xpath('id').text
    end

    def name
      @root.at_xpath('name').text
    end

    def coverage_type
      @root.at_xpath('coverage_type').text
    end

    def plan_year
      @root.at_xpath('plan_year').text
    end

    def carrier
      @root.at_xpath('carrier').elements.inject({}) do |data, element|
        data[element.name.to_sym] = element.text()
        data
      end
    end
  end
end