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

    def enrollee_attributes
      {
        :m_id => member_id,
        :rel_code => map_rel_code,
        :coverage_start => begin_date,
        :coverage_end => end_date,
        :pre_amt => premium_amount
      }
    end

    def map_rel_code
      return "self" if is_subscriber
      case stripped_rel_code
      when "spouse"
        "spouse"
      when "ward"
        "ward"
      else
        "child"
      end
    end

    def stripped_rel_code
      relationship.strip.split("#").last
    end
  end
end
