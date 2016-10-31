module HandlePolicyNotification
  class MemberDetails
    include Virtus.model

    attribute :is_subscriber, Boolean
    attribute :member_id, String
    attribute :premium_amount, Float
    attribute :begin_date, Date
    attribute :end_date, Date
    attribute :eligibility_begin_date, Date
    attribute :relationship, String

    def found_member
      @found_member ||= begin
                          query = Queries::MemberByHbxIdQuery.new(member_id)
                          query.execute
                        end
    end

  end
end
