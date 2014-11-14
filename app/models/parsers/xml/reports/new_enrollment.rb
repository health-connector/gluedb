module Parsers::Xml::Reports
  class NewEnrollment

    include NodeUtils
    
    def initialize(data_xml = nil)  
      @root = data_xml
      build_namespaces
    end

    def policies
      @root.xpath('n1:policy', @namespaces).inject([]) do |data, policy|
        data << policy
      end
    end

    def people
      @root.xpath('n1:policy/n1:enrollees/n1:enrollee/n1:member', @namespaces).inject([]) do |data, member|
        data << member
      end
    end

    def type
      node = @root.at_xpath('n1:type', @namespaces)
      node.blank? ? nil : node.text.strip
    end

    def market
      node = @root.at_xpath('n1:market', @namespaces)
      node.blank? ? nil : node.text.strip
    end
  end
end