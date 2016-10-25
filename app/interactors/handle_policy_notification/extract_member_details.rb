module HandlePolicyNotification
  class ExtractMemberDetails
    # Context Requires:
    # - policy_cv (Openhbx::Cv2::Policy)
    # Context Outputs:
    # - member_detail_collection (array of HandlePolicyNotification::MemberDetails)
    def call
      context.member_detail_collection = extract_members(context.policy_cv)
    end

    def extract_members(policy_cv)
      enrollees = policy_cv.enrollees
      return [] if enrollees.blank?
      enrollees.map do |enrollee|
        member = enrollee.member
        benefit = enrollee.benefit
        HandlePolicyNotification::MemberDetails.new({
           :member_premium => benefit.premium_amount
           :member_id => parse_member_id(member),
           :is_subcriber => enrollee.subscriber?,
           :coverage_start => parse_begin_date(member),
           :coverage_end => parse_end_date(member),
           :eligibility_start => parse_eligibility_date(member)
        })
      end
    end

    def parse_member_id(member)
      return nil if member.id.blank?
      member.id.strip.split("#").last
    end

    def parse_begin_date(benefit)
      parse_date_or_nil(benefit.begin_date)
    end

    def parse_end_date(benefit)
      parse_date_or_nil(benefit.end_date)
    end

    def parse_eligibility_date(benefit)
      parse_date_or_nil(benefit.eligibility_begin_date)
    end

    def parse_date_or_nil(date)
      return nil if date.blank?
      Date.strptime(date, "%Y%m%d") rescue nil
    end
  end
end
