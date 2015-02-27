require 'spreadsheet'
require 'csv'
module Generators::Reports  
  class IrsGroupSerializer

    CALENDER_YEAR = 2014

    def build_irs_group(family)
      builder = Generators::Reports::IrsGroupBuilder.new(family)
      builder.calender_year = CALENDER_YEAR
      builder.process
      builder.irs_group
    end

    def non_aptc
      count = 0
      current = 0

      primary_applicant_ids = []

      Family.all.each do |family|
        current += 1
        
        next if family.households.count > 1
        next if family.active_household.blank?
        next if family.active_household.enrollments_for_year(CALENDER_YEAR).empty?
        next if family.active_household.has_aptc?(CALENDER_YEAR)

        policies = family.active_household.enrollments_for_year(CALENDER_YEAR).map(&:policy)
        next if policies.detect {|pol| multi_version_aptc?(pol) }

        freeman_pols = Person.find('53e69248eb899ad9ca016007').policies
        if (policies & freeman_pols).any?
          puts "found freeman ----#{family.e_case_id.inspect}"
        end

        next if family.active_household.enrollments_for_year(2014).empty?

        irs_group = build_irs_group(family)
        next if irs_group.insurance_policies.empty?
        IrsGroupXml.new(irs_group).serialize

        count += 1
        # puts "processing....#{count}"

        primary_applicant_ids << family.primary_applicant.person.id

        puts "#{family.e_case_id}---#{irs_group.identification_num}"
        
        if count % 250 == 0
          puts "so far --- #{count} --- out of #{current}"
          break
        end
      end

      puts "total non aptc families to report #{count}"
      puts "unique primary applicants #{primary_applicant_ids.uniq.count}"
    end

    def aptc
    end

    private

    def multi_version_aptc?(policy)
      if policy.version > 1
        aptcs = policy.versions.map(&:applied_aptc).map{ |x| x.to_f }
        if aptcs.uniq.size > 1 || (aptcs.uniq[0] != policy.applied_aptc.to_f)
          return true
        end
      end
      false
    end
  end
end