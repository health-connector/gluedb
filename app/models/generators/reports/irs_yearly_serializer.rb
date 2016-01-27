require 'spreadsheet'
require 'csv'
module Generators::Reports  
  class IrsYearlySerializer

    IRS_XML_PATH = "#{Rails.root.to_s}/IRS_MAR3/h41/"
    IRS_PDF_PATH = "#{Rails.root.to_s}/IRS_MAR3/irs1095a/"

    def initialize
      @count = 0
      @policy_id = nil
      @hbx_member_id = nil

      @report_names = {}
      @policies = []
      @plans  = nil

      @position = 0
      @pdf_set = 0
      @irs_set = 0
      @aptc_versions = []

      # @workbook = Spreadsheet::Workbook.new
      # @sheet = @workbook.create_worksheet :name => 'report' 
    end

    def generate_notices
      create_new_pdf_folder
      create_new_irs_folder

      CSV.foreach("#{Rails.root}/1095as_filtered.csv") do |row|
        @position += 1
        if @position%500 == 0
          puts "processed #{@position}"
        end
        process_policy(row[0].strip)
      end
      puts @count
      # @workbook.write "#{Rails.root.to_s}/aptc_multiple_versions2.xls"
    end

    def process_policy_ids(ids)
      create_new_pdf_folder
      create_new_irs_folder
      ids.each do |id|
        process_policy(id)
      end
    end

    def process_policy(policy_id)
      policy = Policy.find(policy_id)
     
      # Skip non APTC policies
      # return if policy.applied_aptc == 0

      # return if multi_version_aptc?(policy)

      # Skip APTC policies
      # next if policy.applied_aptc > 0

      # Skip if enrollees is zero on policy due to wrong end date
      active_enrollees = policy.enrollees.reject{|en| en.canceled?}
      puts '----step1'
      return if active_enrollees.empty?
      puts '----step2'

      # Skip APTC policies with multiple members on policy
      # return if active_enrollees.empty? || (policy.applied_aptc > 0 && active_enrollees.size > 1)

      # if rejected_policy?(policy)
      #   return
      # end

      # return if policies_to_skip.include?(policy.id)

      # if Generators::Reports::MultiVersionAptcLookup.new(policy).assisted_with_single?
      #   if policies_to_skip.include?(policy.id)
      #     puts policy.id
      #   else
      #     @count += 1
      #   end
      # end

      # if Generators::Reports::MultiVersionAptcLookup.new(policy).assisted_multiple?
      #   display_multi_versions(policy)
      # end

      # begin
        @policy_id = policy.id
        @hbx_member_id = policy.subscriber.person.authority_member.hbx_member_id
        notice = Generators::Reports::IrsInputBuilder.new(policy, multi_version_aptc?(policy)).notice

        puts notice.inspect

        create_report_names
        render_xml(notice)
        render_pdf(notice)

        if notice.covered_household.size > 5
          create_report_names
          render_pdf(notice, true)          
        end

        if @count !=0
          if (@count % 250 == 0)
            create_new_pdf_folder
          elsif (@count % 4000 == 0)
            create_new_irs_folder
          end
        end
      # rescue Exception  => e
      #   puts "------------#{policy.id}"
      # end

      notice = nil
      policy = nil
    end

    def rejected_policy?(policy)
      edi_transactions = Protocols::X12::TransactionSetEnrollment.where({ "policy_id" => policy.id })
      if edi_transactions.count == 1 && edi_transactions.first.aasm_state == 'rejected'
        return true
      end
      false
    end

    # Skip policies with more than 1 aptc version
    def multi_version_aptc?(policy)
      if policy.version > 1
        aptcs = policy.versions.map(&:applied_aptc).map{ |x| x.to_f }
        if aptcs.uniq.size > 1 || (aptcs.uniq[0] != policy.applied_aptc.to_f)
          return true
        end
      end
      false
    end

    def create_directory(path)
      if Dir.exists?(path)
        FileUtils.rm_rf(path)
      end
      Dir.mkdir path
    end

    def render_xml(notice)
      xml_report = Generators::Reports::IrsYearlyXml.new(notice, @count).serialize.to_xml(:indent => 2)
      File.open("#{IRS_XML_PATH + @h41_folder_name}/#{@report_names[:xml]}.xml", 'w') do |file|
        file.write xml_report
      end
    end

    def render_pdf(notice, multiple = false)
      pdf_notice = Generators::Reports::IrsYearlyPdfReport.new(notice, multiple)
      pdf_notice.render_file("#{IRS_PDF_PATH + @irs1095_folder_name}/#{@report_names[:pdf]}.pdf")
    end

    def create_new_pdf_folder
      @pdf_set += 1
      folder_number = prepend_zeros(@pdf_set.to_s, 3)
      @irs1095_folder_name = "DCHBX_IRS1095A_#{Time.now.strftime('%H_%M_%d_%m_%Y')}_#{folder_number}"
      create_directory "#{IRS_PDF_PATH + @irs1095_folder_name}"
    end

    def create_new_irs_folder
      @irs_set += 1
      folder_number = prepend_zeros(@irs_set.to_s, 3)
      @h41_folder_name = "DCHBX_H41_#{Time.now.strftime('%H_%M_%d_%m_%Y')}_#{folder_number}"
      create_directory "#{IRS_XML_PATH + @h41_folder_name}"
    end

    def create_manifest
      Generators::Reports::Manifest.new.create("#{IRS_XML_PATH + @h41_folder_name}")
    end

    def active_policies
      @plans = Plan.where({:metal_level => {"$not" => /catastrophic/i}, :coverage_type => /health/i}).map(&:id)
      @policies = PolicyStatus::Active.between(Date.new(2013,12,31), Date.new(2014,12,31)).results.where({
        :plan_id => {"$in" => @plans}, :employer_id => nil
        }).where(PolicyQueries.without_aptc)

      @plans = nil
    end

    def is_valid_policy?(policy)
      return false if policy.subscriber.person.authority_member.blank?
      policy.subscriber.person.authority_member.hbx_member_id == policy.subscriber.hbx_member_id
    end

    def create_report_names
      @count += 1
      if (@count%10 == 0)
        puts "-----at #{@position}"
        puts "-----generated #{@count}"
      end

      sequential_number = @count.to_s
      sequential_number = prepend_zeros(sequential_number, 6)
      @report_names = {
        pdf: "#{sequential_number}_HBX_01_#{@hbx_member_id}_#{@policy_id}_IRS1095A",
        xml: "EOY_Request_#{sequential_number}_#{Time.now.utc.iso8601.gsub(/-|:/,'')}"
      }
    end

    def policies_to_skip
      # slcsp_fixes = [7884, 8269, 8393, 12236, 15585, 15824, 19846]
      # versions = [7884, 8560, 10979, 11214, 15585, 16246, 16465, 17247, 20079, 20749, 20764, 21445, 24050, 26705, 27098, 28798, 30561]
      duplicates = [8026, 23120, 16245, 16246, 19203, 22375, 8376, 12057, 28798, 12153, 8642, 22015, 22167, 22168, 17584]
      # rejected = [17584, 19203, 22015, 22064, 22335, 22375, 22581, 22855, 22901]
      # processed = [8315, 8435, 9402, 9572, 9632, 10349, 10416, 10437, 10548, 10624, 10647, 10673, 11545, 20719]
      (duplicates).uniq
    end


    def display_multi_versions(policy)
      aptc_lookup = Generators::Reports::MultiVersionAptcLookup.new(policy)

        puts policy.versions.map{ |x| "#{x.updated_at.to_s}----#{x.applied_aptc.to_f}" }.inspect
        puts "#{policy.updated_at.to_s}----#{policy.applied_aptc.to_f}"
        puts "#{policy.id}----#{policy.subscriber.person.full_name}"
        puts policy.subscriber.coverage_start
        puts policy.subscriber.coverage_end

        # data = [policy.id, policy.subscriber.person.full_name]
        # data += [policy.subscriber.coverage_start, (policy.subscriber.coverage_end || Date.new(2014, 12, 31))]
        monthly_arr = []
        aptc_lookup.monthly_aptcs.each_index do |i|
          next if aptc_lookup.monthly_aptcs[i].nil?
          monthly_arr << "#{i+1}|#{aptc_lookup.monthly_aptcs[i].to_f}"
        end

        puts monthly_arr.join(', ')

        # data += aptc_lookup.monthly_aptcs
        # @sheet.row(index).concat data
        # index += 1

        @count += 1
    end

    private

    def prepend_zeros(number, n)
      (n - number.to_s.size).times { number.prepend('0') }
      number
    end
  end
end