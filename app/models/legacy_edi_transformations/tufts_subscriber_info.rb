module LegacyEdiTransformations
  class TuftsSubscriberInfo
    attr_reader :subscriber_id,
                :hios_id,
                :carrier_assigned_policy_id,
                :subscriber_start
    def initialize(sub_id, h_id, capi, s_start)
      @subscriber_id = sub_id
      @hios_id = h_id
      @carrier_assigned_policy_id = capi
      @subscriber_start = s_start
    end

    def locate_policy_information
      return nil if subscriber_id.blank?
      return nil if hios_id.blank?
      return nil if subscriber_start.blank?
      plan_ids = Plan.where(:hios_plan_id => hios_id).map(&:id)
      return nil if plan_ids.blank?
      potential_policies = Policy.where(
        {
          :plan_id => {"$in" => plan_ids},
          "enrollees.m_id" => subscriber_id
        }
      )
      return nil if potential_policies.blank?
      matching_pols = potential_policies.select do |pol|
        pol.enrollees.any? do |en|
          en.subscriber? &&
            (en.m_id == subscriber_id) &&
            en.coverage_start.present? &&
            (subscriber_start == en.coverage_start.strftime("%Y%m%d"))
        end
      end
      return nil if matching_pols.blank?
      extract_needed_information(matching_pols.first)
    end

    protected

    def extract_needed_information(pol)
      emp = pol.employer
      return [pol.eg_id, nil, nil] if emp.blank?
      [pol.eg_id, emp.name, emp.fein]
    end
  end
end
