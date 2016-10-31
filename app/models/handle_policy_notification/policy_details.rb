module HandlePolicyNotification
  class PolicyDetails
    include Virtus.model

    attribute :market, String # Should be either "shop" or "individual"
    attribute :enrollment_group_id, String
    attribute :pre_amt_tot, String
    attribute :tot_res_amt, String
    attribute :tot_emp_res_amt, String
  end
end
