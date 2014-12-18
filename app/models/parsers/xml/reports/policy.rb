module Parsers::Xml::Reports
  class Policy

    include NodeUtils
    attr_reader :root, :root_elements, :enrollees, :enrollment, :responsible_party, :comments, :broker
    
    def initialize(parser = nil)
      @root = parser
      build_namespaces
      parse_policy_xml
    end

    def parse_policy_xml
      @root_elements = @root.elements.inject({}) do |data, node|
        data[node.name.to_sym] = parse_uri(node.text().strip()) if node.elements.count.zero?
        data
      end

      @enrollees = @root.xpath('n1:enrollees/n1:enrollee', @namespaces).inject([]) do |data, node|
        data << Enrollee.new(node, @namespaces)
      end

      broker = @root.at_xpath('n1:broker', @namespaces)
      if broker
        @broker =  {
          id: @root.at_xpath('n1:broker/n1:id/n1:id').text.strip,
          name: @root.at_xpath('n1:broker/n1:name').text.strip,
          is_active: @root.at_xpath('n1:broker/n1:is_active').text.strip
        }
      end

      @responsible_party = extract_elements(@root.at_xpath('n1:responsible_party', @namespaces))

      @enrollment = @root.at_xpath('n1:enrollment', @namespaces).elements.inject({}) do |data, node|
        data[node.name.to_sym] = ((node.name == 'plan') ? PolicyPlan.new(node, @namespaces) : node.text.strip)
        data
      end

      @comments = extract_elements(@root.at_xpath('n1:comments', @namespaces))
    end

    # def covered_individuals
    #   @root.xpath("n1:enrollees/n1:subscriber").each do |individual|
    #     @individuals << individual
    #   end

    #   @root.xpath("n1:enrollees/n1:members/n1:member").each do |individual|
    #     @individuals << individual
    #   end
    # end

    # def id
    #   @root.at_xpath("n1:id").text
    # end

    # def plan
    #   @root.at_xpath("n1:enrollment/n1:plan/n1:name").text
    # end

    # def start_date
    #   Date.strptime(@individuals[0].at_xpath("n1:benefit/n1:begin_date").text,'%Y%m%d')
    # end

    # def end_date
    #   if @individuals[0].at_xpath("n1:benefit/n1:end_date")
    #     Date.strptime(@individuals[0].at_xpath("n1:benefit/n1:end_date").text,'%Y%m%d')
    #   end
    # end

    # def household_aptc
    # end

    # def applied_patc
    #   @root.at_xpath("n1:enrollment/n1:individual_market/n1:applied_aptc_amount").text
    # end

    # def elected_aptc
    # end

    # def coverage_type
    #   coverage = @root.at_xpath("n1:enrollment/n1:plan/n1:coverage_type").text
    #   coverage.split("#")[1]
    # end

    # def total_monthly_premium
    #   @root.at_xpath("n1:enrollment/n1:premium_amount_total").text
    # end

    # def qhp_policy_num
    # end

    # def qhp_issuer_ein
    # end

    # def qhp_number
    #   @root.at_xpath("n1:enrollment/n1:plan/n1:qhp_id").text.split("-")[0]
    # end

    # def qhp_id
    #   @root.at_xpath("n1:enrollment/n1:plan/n1:qhp_id").text.gsub(/-/,"")
    # end
  end
end
