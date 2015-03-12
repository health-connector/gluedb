require 'spreadsheet'
require 'csv'
module Generators::Reports  
  class IrsMonthlySerializer

    CALENDER_YEAR = 2014

    def initialize
      # @logger = Logger.new("#{Rails.root}/log/h36_exceptions.log")
      @logger = Logger.new("#{Rails.root}/log/duplicate_policies_with_dates.log")
    end

    def build_irs_group(family)
      builder = Generators::Reports::IrsGroupBuilder.new(family)
      builder.calender_year = CALENDER_YEAR
      builder.process
      builder.irs_group
    end

    def non_aptc
      count = 0
      current = 0

      folder_count = 1
      create_new_irs_folder(folder_count)
      create_directory("#{Rails.root}/h36xmls/transmission")

      freeman_pols = Person.find('53e69248eb899ad9ca016007').policies.map(&:id)
      start = Time.now

      Family.all.each do |family|

        current += 1

        if current % 100 == 0
          puts "checking #{current}"
        end

        next if family.households.count > 1 || family.active_household.nil? || family.primary_applicant.nil?
        # next unless family.active_household.has_aptc?(CALENDER_YEAR)

        active_enrollments = family.active_household.enrollments_for_year(CALENDER_YEAR)
        # Generators::Reports::FamilyTaxHousehold.new(family.active_household, CALENDER_YEAR).build
        # count += 1
        # puts "proessed---#{count}"
        # next

        next if active_enrollments.empty? # || active_enrollments.count > 1

        if active_enrollments.count > 1
          count += 1
        end
        
        next

        next if active_enrollments.map(&:policy).any? {|pol| multi_version_aptc?(pol) }


        policy_ids = active_enrollments.map(&:policy_id)

        next if (policy_ids & freeman_pols).any?
        next if (policy_ids & policies_to_skip).any?

        policy_ids = nil

        if family.family_members.any? {|x| x.person.authority_member.ssn == '999999999' }
          @logger.info "ssn with all 9's --- #{family.e_case_id.inspect}"
          next
        end

        if (family.family_members.map(&:person_id) & smash_list).any?
          next
        end

        irs_group = build_irs_group(family)       
        next if irs_group.insurance_policies.empty?
 
        if irs_group.insurance_policies.any?{|policy| policy.no_coverage? || policy.no_premium_amount? }
          @logger.info "blank policy --- #{family.e_case_id.inspect}"
          next          
        end

        group_xml = IrsMonthlyXml.new(irs_group, family.e_case_id)
        group_xml.folder_name = @h36_folder_name
        group_xml.serialize

        count += 1

        if count % 2000 == 0
          merge_and_validate_xmls(folder_count)
          folder_count += 1
          create_new_irs_folder(folder_count)
        end
        
        if count % 500 == 0
          puts "so far --- #{count} --- out of #{current}"
          puts "time taken for current record ---- #{Time.now - start} seconds"
          start = Time.now
        end

        active_enrollments = nil
        irs_group = nil
        group_xml = nil
      end

      puts "----#{count}"
    end

    def merge_and_validate_xmls(folder_count)
      folder_num = prepend_zeros(folder_count.to_s, 5)
      xml_merge = Generators::Reports::IrsXmlMerger.new("#{Rails.root}/h36xmls/#{@h36_folder_name}", folder_num)
      xml_merge.process
      xml_merge.validate
    end

    def aptc
    end

    private

    def smash_list
      ['54be7e30c403b6e0fb0000a9', '53e692a4eb899ad9ca01862d', '53e69409eb899ad9ca01fe48', '53e68ef8eb899ad9ca004329', '54f0ee7cc403b659f9000b12', '53f3b7b6eb899a201d0003b9']
    end

    def create_new_irs_folder(folder_count)
      folder_number = prepend_zeros(folder_count.to_s, 3)
      @h36_folder_name = "DCHBX_H36_#{Time.now.strftime('%H_%M_%d_%m_%Y')}_#{folder_number}"
      create_directory "#{Rails.root}/h36xmls/#{@h36_folder_name}"
    end

    def policies_to_skip
      no_slcsp = [12483, 21566, 24403, 26231, 30560, 54545, 54560, 58358, 59987]
      update_required = [8315, 8318, 8558, 9326, 11423, 17597, 19297, 19335, 24268, 25045]
      wrong_ssns = [691, 8383, 12082]
      wrong_dates = [8369, 10486, 15910, 22995, 22997]

      no_slcsp + update_required + wrong_ssns + wrong_dates
    end

    def multi_version_aptc?(policy)
      if policy.version > 1
        aptcs = policy.versions.map(&:applied_aptc).map{ |x| x.to_f }
        if aptcs.uniq.size > 1 || (aptcs.uniq[0] != policy.applied_aptc.to_f)
          return true
        end
      end
      false
    end

    def prepend_zeros(number, n)
      (n - number.to_s.size).times { number.prepend('0') }
      number
    end

    def create_directory(path)
      if Dir.exists?(path)
        FileUtils.rm_rf(path)
      end
      Dir.mkdir path
    end
  end
end