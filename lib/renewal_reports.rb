require "spreadsheet"

class RenewalReports

  def initialize(report_type = 'assisted')
    @report_type = report_type
  end
  
  def process
    CanonicalVocabulary::RenewalSerializer.new(@report_type).serialize("#{@report_type}_groups.xls")
  end

  def generate_groupids
    scope = (@report_type == 'assisted' ? 'insurance_assisted' : 'unassisted')
    policies = Policy.individual_market.send(scope).select{|policy| policy.active_and_renewal_eligible?}
    groups = policies.map{|policy| policy.application_group_id}.uniq.compact
    valid_groups = groups.select{|group_id| valid_application_group?(group_id)}
    generate_spreadsheet(valid_groups, "#{@report_type}_groups.xls")
  end

  def generate_spreadsheet(group_ids, file)
    puts group_ids.count
    workbook = Spreadsheet::Workbook.new
    sheet = workbook.create_worksheet :name => 'ids'
    index = 0
    group_ids.each do |id|
      sheet.row(index).concat [id.to_s]
      index += 1
    end
    workbook.write "#{Rails.root.to_s}/#{file}"
  end

  private

  def valid_application_group?(group_id)
    group = Family.find(group_id)
    return false if group.nil?
    with_no_authoriy = group.people.detect{|people| people.authority_member.blank?}
    with_no_authoriy.nil? ? true : false
  end
end