module HandlePolicyNotification
  class MemberChange
    include Virtus.model
    
    attribute :member_id, String
    attribute :premium_amount, String
    attribute :begin_date, Date
    attribute :end_date, Date
  end
end
