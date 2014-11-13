module Parsers::Xml::Reports
  class Enrollee

    def initialize(parser = nil)
      @root = parser
    end

    def member
      Individual.new(@root.at_xpath('member'))
    end

    def benefit
      @root.at_xpath('benefit').elements.inject({}) do |data, element|
        data[element.name.to_sym] = element.text().strip()
        data
      end
    end

    def is_subscriber
      @root.at_xpath('is_subscriber').text()
    end
  end
end