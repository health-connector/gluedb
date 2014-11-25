module Parsers::Xml::Reports
  class Enrollee

    def initialize(parser = nil, namespaces = {})
      @root = parser
      @namespaces = namespaces
    end

    def member
      Individual.new(@root.at_xpath('n1:member', @namespaces))
    end

    def benefit
      @root.at_xpath('n1:benefit', @namespaces).elements.inject({}) do |data, element|
        data[element.name.to_sym] = element.text.strip
        data
      end
    end

    def is_subscriber
      @root.at_xpath('n1:is_subscriber', @namespaces).text
    end
  end
end