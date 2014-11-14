class CreatePolicyRequest
  def self.from_xml(payload = nil)
    @policy = Parsers::Xml::Reports::Policy.new(payload)
    plan = @policy.enrollment[:plan]

    request = {
      hois_id: plan.id,
      plan_year: plan.plan_year,
      carrier_id: plan.carrier[:id],
      carrier_to_bill: plan.carrier[:name]
    }

    request.merge!(@policy.root_elements)
    request.merge!({ broker_npn: @policy.broker[:id] }) if @policy.broker
    request.merge!({ enrollees: serialize_enrollees })
    request
  end

  private

  def self.serialize_enrollees
    @policy.enrollees.inject([]) do |data, enrollee|
      relationship = enrollee.member.relationships[0]
      rel_code = (relationship.nil? ? 'self' : relationship[:relationship_uri])
      data << {
        m_id: enrollee.member.member_id,
        rel_code: rel_code,
        coverage_start: enrollee.benefit[:begin_date],
        pre_amt: enrollee.benefit[:premimum_amount],
        ben_stat: 'active',
        emp_stat: 'active'
      }
    end 
  end
end