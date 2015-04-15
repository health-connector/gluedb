require "spreadsheet"

module CanonicalVocabulary
  class RenewalSerializer

    CV_API_URL = "http://localhost:3000/api/v1/"

    def initialize(report_type)
      (report_type == "assisted" ? initialize_assisted : initialize_unassisted)
      @logger = Logger.new("#{Rails.root}/log/#{report_type}_renewals.log")
    end

    def serialize(file_name)
      worksheet = Spreadsheet.open("#{Rails.root.to_s}/#{file_name}").worksheet(0)
      count = 0 
      worksheet.rows[1..10].in_groups_of(5, false) do |group_ids| 
        serialize_groupids(group_ids)
        count += 1
        puts "--------processed--#{count * 5}"
      end
      write_reports
    end

    def serialize_groupids(group_ids)
      begin
        groups_xml = Net::HTTP.get(URI.parse("#{CV_API_URL}families?ids[]=#{group_ids.join("&ids[]=")}&user_token=zUzBsoTSKPbvXCQsB4Ky"))
        root = Nokogiri::XML(groups_xml).root
        root.xpath("n1:application_group").each do |family_xml|
          process_family(family_xml)
        end
      rescue Exception => e
        @logger.info group_ids.join(",")
      end
    end

    def process_family(family_xml)
      begin
        family = Parsers::Xml::Reports::Family.new(family_xml)
        if family.size == 1
          @single.append_household(family)
        else
          family.size <= 6 ? @multiple.append_household(family) :
          @super_multiple.append_household(family)
        end
      rescue Exception => e
        @logger.info family_xml.at_xpath("n1:id").text.match(/\w+$/)[0]
      end
    end

    def initialize_assisted 
      @single = CanonicalVocabulary::Renewals::Assisted.new({ 
        file: "Manual Renewal Single IA).xls",
        log_file: "ia_renewals_internal.log",
        other_members: 0
      })
      @multiple = CanonicalVocabulary::Renewals::Assisted.new({ 
        file: "Manual Renewal Multiple IA).xls",
        log_file: "ia_renewals_internal.log",
        other_members: 5
      })
      @super_multiple = CanonicalVocabulary::Renewals::Assisted.new({ 
        file: "Manual Renewal Super IA).xls",
        log_file: "ia_renewals_internal.log",
        other_members: 8
      })
    end

    def initialize_unassisted
      @single = CanonicalVocabulary::Renewals::Unassisted.new({ 
        file: "Manual Renewal Single UQHP).xls",
        log_file: "uqhp_renewals_internal.log",
        other_members: 0
      })
      @multiple = CanonicalVocabulary::Renewals::Unassisted.new({ 
        file: "Manual Renewal Multiple UQHP).xls",
        log_file: "uqhp_renewals_internal.log",
        other_members: 5
      })
      @super_multiple = CanonicalVocabulary::Renewals::Unassisted.new({ 
        file: "Manual Renewal Super UQHP).xls",
        log_file: "uqhp_renewals_internal.log",
        other_members: 8
      })
    end

    def write_reports
      @single.book.write @single.file
      @multiple.book.write @multiple.file
      @super_multiple.book.write @super_multiple.file
    end
  end
end
