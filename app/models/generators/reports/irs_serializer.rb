module Generators::Reports  
  class IrsSerializer
    class << self

      def generate_notices
        # Currently its for APTC
        active_policies.where(PolicyQueries.with_aptc).each do |policy|
          if is_valid_policy?(policy)
            notice = Generators::Reports::IrsInputBuilder.new(policy).notice
            render_pdf(notice)
            render_xml(notice)
          end
        end     
      end

      def render_xml(notice)
        xml_report = Generators::Reports::IrsYearlyXml.new(notice).serialize.to_xml(:indent => 2)

        File.open("#{Rails.root.to_s}/sample.xml", 'w') do |file|
          file.write xml_report
        end
      end

      def render_pdf(notice)
        pdf_notice = Generators::Reports::IrsPdfReport.new(notice)
        pdf_notice.render_file("#{Rails.root.to_s}/irs_sample.pdf")
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
          })
      end

      def is_valid_policy?(policy)
        return false if policy.subscriber.person.authority_member.blank?
        policy.subscriber.person.authority_member.hbx_member_id == policy.subscriber.hbx_member_id
      end
    end
  end
end