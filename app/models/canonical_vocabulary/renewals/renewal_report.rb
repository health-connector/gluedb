require "spreadsheet"
module CanonicalVocabulary
	module Renewals

    class PolicyProjection 
      attr_reader :current
      def initialize(app_group, coverage_type)
        @coverage_type = coverage_type
        policy_builder = CanonicalVocabulary::Renewals::PolicyBuilder.new(app_group)
        @current = policy_builder.current_insurance_plan(coverage_type)
      end
    end

		class RenewalReport
      
      CV_API_URL = "http://localhost:3000/api/v1/"

      def initialize(options)
        @book  = Spreadsheet::Workbook.new
        @sheet = book.create_worksheet :name => 'Manual Renewal'
        @renewal_logger = Logger.new("#{Rails.root}/log/#{options[:log_file]}")
        @file  = options[:file]
        @row = 1
      end
      
      def setup(family)
        @family = family

        # individuals = find_many_individuals_by_id(@family.family_member_person_ids)
        # @primary = individuals.detect { |i| (i.id == @family.primary_applicant_id || individuals.count == 1) }
        @primary = @family.primary_applicant
        raise "Primary Applicant Address Not Present" if @primary.person.addresses.empty?

        @other_members = @family.family_members.reject { |i| i == @primary }

        @dental = PolicyProjection.new(@family, "dental")
        @health = PolicyProjection.new(@family, "health")

        if @health.current.nil? && @dental.current.nil?
          raise "No active health or dental policy"
        end
      end

      def append_household(family)
        begin
          setup(family)
          build_report
        rescue Exception  => e
          @renewal_logger.info "#{family.id.match(/\w+$/)},#{e.inspect}"
        end
      end

      private

      def find_many_individuals_by_id(ids)
        members_xml = Net::HTTP.get(URI.parse("#{CV_API_URL}people?ids[]=#{ids.join("&ids[]=")}&user_token=zUzBsoTSKPbvXCQsB4Ky"))
        individual_elements = Nokogiri::XML(members_xml).root.xpath("n1:individual")
        individual_elements.map { |i| Parsers::Xml::Reports::Individual.new(i) }
      end

      def num_blank_members
        @other_members_limit - @other_members.count
      end
    end
  end
end
