module HandlePolicyNotification
  class MemberDetails
    include Virtus.model

    attribute :member_id, String
    attribute :is_subscriber, Boolean
    attribute :member_premium, Boolean
    attribute :coverage_start, Date
    attribute :coverage_end, Date
    attribute :eligibility_start, Date

    def found_member
      @found_member ||= begin
                          query = Queries::MemberByHbxIdQuery.new(member_id)
                          query.execute
                        end
    end
  end
end
