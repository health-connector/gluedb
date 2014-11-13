module Parsers::Xml::Reports
  module NodeUtils

    def root_level_elements
      @root_elements = @root.elements.inject({}) do |data, node|
        data[node.name.to_sym] = parse_uri(node.text().strip()) if node.elements.count.zero?
        data
      end
      # @root_elements = OpenStruct.new(identifiers)
    end

    def extract_elements(node)
      return nil if node.nil?
      independent_element = node.elements.detect{|node| node.elements.count.zero?}
      independent_element.nil? ? extract_collection(node) : extract_properties(node)
    end

    def extract_collection(node)
      node.elements.inject([]) do |data, node|
        data << extract_properties(node)
      end
    end

    def extract_properties(node)
      # OpenStruct.new(properties)
      node.elements.inject({}) do |data, node|
        data[node.name.to_sym] = (node.elements.count.zero? ? parse_uri(node.text().strip()) : extract_elements(node))
        data
      end
    end

    def parse_date(date)
      Date.parse(date)
    end

    def parse_uri(value)
      if value.match(/^urn\:/)
        return value.split('#')[1]
      end
      value
    end
  end
end