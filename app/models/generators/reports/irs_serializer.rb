module Generators::Reports  
  class IrsSerializer

    IRS_XML_PATH = "#{Rails.root.to_s}/irs1095a_xml/"
    IRS_PDF_PATH = "#{Rails.root.to_s}/irs1095a_pdf/"

    def initialize
      @count = 0
      @policy_id = nil
      @hbx_member_id = nil
      @report_names = {}
    end

    def generate_notices
      set = 1 
      lower_bound = 0
      batch_size  = 200
      upper_bound = 199

      while true
        folder_number = prepend_zeros(set.to_s, 6)

        @folder_name = "DCHBX_#{Date.today.strftime('%d_%m_%Y')}_#{folder_number}"
        create_directory "#{IRS_PDF_PATH + @folder_name}"
        create_directory "#{IRS_XML_PATH + @folder_name}"

        active_policies[lower_bound..upper_bound].each do |policy|
          @policy_id = policy.id
          @hbx_member_id = policy.subscriber.hbx_member_id
          notice = Generators::Reports::IrsInputBuilder.new(policy).notice
          create_report_names
          render_pdf(notice)
          render_xml(notice)
        end
        Generators::Reports::Manifest.new.create("#{IRS_XML_PATH + @folder_name}")
        lower_bound = upper_bound + 1
        upper_bound += batch_size
        set += 1
        break if active_policies[lower_bound..upper_bound].nil?
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
      File.open("#{IRS_XML_PATH + @folder_name}/#{@report_names[:xml]}.xml", 'w') do |file|
        file.write xml_report
      end
    end

    def render_pdf(notice)
      puts "#{IRS_XML_PATH + @folder_name}/#{@report_names[:pdf]}.pdf"
      pdf_notice = Generators::Reports::IrsPdfReport.new(notice)
      pdf_notice.render_file("#{IRS_PDF_PATH + @folder_name}/#{@report_names[:pdf]}.pdf")
    end

    def active_policies
      plans = Plan.where({:metal_level => {"$not" => /catastrophic/i}, :coverage_type => /health/i}).map(&:id)

      p_repo = {}

      p_map = Person.collection.aggregate([{"$unwind"=> "$members"}, {"$project" => {"_id" => 0, member_id: "$members.hbx_member_id", person_id: "$_id"}}])

      p_map.each do |val|
        p_repo[val["member_id"]] = val["person_id"]
      end

      PolicyStatus::Active.between(Date.new(2013,12,31), Date.new(2014,12,31)).results.where({
        :plan_id => {"$in" => plans}, :employer_id => nil
        }).select{|pol| is_valid_policy?(pol)}[1..20]
    end

    def is_valid_policy?(policy)
      return false if policy.subscriber.person.authority_member.blank?
      policy.subscriber.person.authority_member.hbx_member_id == policy.subscriber.hbx_member_id
    end

    def create_report_names
      @count += 1
      puts "-------------processing #{@count}"
      sequential_number = @count.to_s
      sequential_number = prepend_zeros(sequential_number, 6)
      @report_names = {
        pdf: "#{sequential_number}_HBX_01_#{@hbx_member_id}_#{@policy_id}_IRS1095A",
        xml: "#{sequential_number}_HBX_01_#{@hbx_member_id}_#{@policy_id}_IRS1095A"
      }
    end

    private

    def prepend_zeros(number, n)
      (n - number.to_s.size).times { number.prepend('0') }
      number
    end
  end
end