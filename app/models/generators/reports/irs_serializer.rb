module Generators::Reports  
  class IrsSerializer

    IRS_XML_PATH = "#{Rails.root.to_s}/IRS_Reports/h41/"
    IRS_PDF_PATH = "#{Rails.root.to_s}/IRS_Reports/irs1095a/"

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
    end

    def create_new_pdf_folder
      @pdf_set += 1
      folder_number = prepend_zeros(@pdf_set.to_s, 3)
      @irs1095_folder_name = "DCHBX_IRS1095A_#{Date.today.strftime('%d_%m_%Y')}_#{folder_number}"
      create_directory "#{IRS_PDF_PATH + @irs1095_folder_name}"
    end

    def create_new_irs_folder
      @irs_set += 1
      folder_number = prepend_zeros(@irs_set.to_s, 3)
      @h41_folder_name = "DCHBX_H41_#{Date.today.strftime('%d_%m_%Y')}_#{folder_number}"
      create_directory "#{IRS_XML_PATH + @h41_folder_name}"
    end

    def create_manifest
      Generators::Reports::Manifest.new.create("#{IRS_XML_PATH + @h41_folder_name}")
    end

    def generate_notices
      lower_bound = 0
      batch_size  = 10
      upper_bound = 9
      active_policies

      create_new_pdf_folder
      create_new_irs_folder

      while true
        @policies[lower_bound..upper_bound].each do |policy|
          next unless is_valid_policy?(policy)

          @position += 1
          @policy_id = policy.id
          @hbx_member_id = policy.subscriber.hbx_member_id
          
          notice = Generators::Reports::IrsInputBuilder.new(policy).notice
          create_report_names
          render_pdf(notice)

          if notice.covered_household.size > 5
            create_report_names
            render_pdf(notice, true)          
          end

          render_xml(notice)

          if (@position % 200 == 0)
            create_new_pdf_folder
          elsif (@position % 5000 == 0)
            create_new_irs_folder
          end

          notice = nil
        end

        lower_bound = upper_bound + 1
        upper_bound += batch_size

        if @policies[lower_bound..upper_bound].nil?
          # Generators::Reports::Manifest.new.create("#{IRS_XML_PATH + @h41_folder_name}")
          break
        end
      end
    end

    def create_directory(path)
      if Dir.exists?(path)
        FileUtils.rm_rf(path)
      end
      Dir.mkdir path
    end

    def render_xml(notice)
      xml_report = Generators::Reports::IrsYearlyXml.new(notice).serialize.to_xml(:indent => 2)
      File.open("#{IRS_XML_PATH + @h41_folder_name}/#{@report_names[:xml]}.xml", 'w') do |file|
        file.write xml_report
      end
    end

    def render_pdf(notice, multiple = false)
      pdf_notice = Generators::Reports::IrsPdfReport.new(notice, multiple)
      pdf_notice.render_file("#{IRS_PDF_PATH + @irs1095_folder_name}/#{@report_names[:pdf]}.pdf")
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
      puts "-------------processing #{@count}"

      sequential_number = @count.to_s
      sequential_number = prepend_zeros(sequential_number, 5)
      @report_names = {
        pdf: "#{sequential_number}_HBX_01_#{@hbx_member_id}_#{@policy_id}_IRS1095A",
        xml: "EOY_Request_#{sequential_number}_#{Time.now.utc.iso8601.gsub(/-|:/,'')}"
      }
    end

    private

    def prepend_zeros(number, n)
      (n - number.to_s.size).times { number.prepend('0') }
      number
    end
  end
end