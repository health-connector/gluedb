module HandleEnrollmentEvent
  class ExtractMemberDetails
    include Interactor
    # Context Requires:
    # - policy_cv (Openhbx::Cv2::Policy)
    # Context Outputs:
    # - member_detail_collection (array of HandleEnrollmentEvent::MemberDetails)
    def call
      return if context.policy_cv.nil?
      context.member_detail_collection = extract_members(context.policy_cv)
    end

    def extract_members(policy_cv)
      enrollees = policy_cv.enrollees
      return [] if enrollees.blank?
      enrollees.map do |enrollee|
        member = enrollee.member
        benefit = enrollee.benefit
        HandleEnrollmentEvent::MemberDetails.new({
           :member_information => enrollee,
           :premium_amount => benefit.premium_amount,
           :member_id => parse_member_id(member),
           :is_subscriber => enrollee.subscriber?,
           :begin_date => parse_begin_date(benefit),
           :end_date => parse_end_date(benefit),
           :relationship => parse_relationship(member),
           :eligibility_begin_date => parse_eligibility_date(benefit)
        })
      end
    end

    def parse_relationship(member)
      first_relationship = member.person_relationships.first
      return nil if first_relationship.blank?
      rel_value = first_relationship.relationship_uri
      return nil if rel_value.blank?
      rel_value
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

    def parse_relationshipo
      "child"
    end
  end
end
