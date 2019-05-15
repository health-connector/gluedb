module LegacyEdiTransformations
  class TuftsSubscriberInfo
    attr_reader :subscriber_id,
                :hios_id,
                :exchange_assigned_policy_id,
                :subscriber_start
    def initialize(sub_id, h_id, eapi, s_start)
      @subscriber_id = sub_id
      @hios_id = h_id
      @exchange_assigned_policy_id = eapi
      @subscriber_start = s_start
    end

    def locate_policy_information
      return nil if @exchange_assigned_policy_id.blank?
      potential_policies = Policy.where(
        {
          :eg_id => exchange_assigned_policy_id
        }
      )
      return nil if potential_policies.blank?
      extract_needed_information(potential_policies.first)
    end

    protected

    def extract_needed_information(pol)
      emp = pol.employer
      return [pol.eg_id, nil, nil] if emp.blank?
      [pol.eg_id, emp.name, emp.fein]
    end
  end
end
