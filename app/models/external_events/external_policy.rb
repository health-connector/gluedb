module ExternalEvents
  class ExternalPolicy
    attr_reader :policy_node
    attr_reader :plan

    include Handlers::EnrollmentEventXmlHelper

    # m_node : Openhbx::Cv2::EnrolleeMember
    def initialize(p_node, p_record)
      @policy_node = p_node
      @plan = p_record
    end

    def extract_pre_amt_tot
      0.00
    end

    def extract_tot_res_amt
      0.00
    end

    def extract_enrollee_premium(enrollee)
      pre_string = Maybe.new(enrollee).benefit.premium_amount.value
      return 0.00 if pre_string.blank?
      BigDecimal.new(pre_string)
    end

    def extract_rel_from_me(rel)
      simple_relationship = Maybe.new(rel).relationship_uri.strip.split("#").last.downcase.value
      case simple_relationship of
      when "spouse", "life_partner", "domestic_partner"
        "spouse"
      when "ward"
        "ward"
      else
        "child"
      end
    end

    def extract_rel_from_sub(rel)
      simple_relationship = Maybe.new(rel).relationship_uri.strip.split("#").last.downcase.value
      case simple_relationship of
      when "spouse", "life_partner", "domestic_partner"
        "spouse"
      when "court_appointed_guardian"
        "ward"
      else
        "child"
      end
    end

    def extract_rel_code(enrollee)
      sub_id = subscriber_id
      mem_id = extract_member_id(enrollee)
      prs = Maybe.new(enrollee).member.person_relationships.value
      return "child" if prs.blank?
      me_to_sub = prs.select do |pr|
        subj_ind = Maybe.new(pr).subject_individual.strip.split("#").last.value
        obj_ind = Maybe.new(pr).object_individual.strip.split("#").last.value
        (subj_ind == mem_id) && (obj_ind == sub_id)
      end
      sub_to_me = prs.select do |pr|
        subj_ind = Maybe.new(pr).subject_individual.strip.split("#").last.value
        obj_ind = Maybe.new(pr).object_individual.strip.split("#").last.value
        (subj_ind == sub_id) && (obj_ind == mem_id)
      end
      return "child" if (me_to_sub.empty? && sub_to_me.empty?)
      return extract_rel_from_me(me_to_sub.first) if me_to_sub.any?
      return extract_rel_from_sub(sub_to_me.first) if me_to_sub.any?
      "child"
    end

    def build_enrollee(policy, enrollee_node)
      member_id = extract_member_id(enrollee_node)
      policy.enrollees << Enrollee.new({
        :m_id => member_id,
        :rel_code => extract_rel_code(member),
        :ben_stat => "active",
        :emp_state => "active",
        :coverage_start => extract_enrollee_start(enrollee_node),
        :pre_amt => extract_enrollee_premium(enrollee_node)
      })
      policy.save!
    end

    def subscriber_id
      @subscriber_id ||= begin
        sub_node = extract_subscriber(@policy_node)
        extract_member_id(sub_node)
      end
    end

    def build_subscriber(policy)
      sub_node = extract_subscriber(@policy_node)
      policy.enrollees << Enrollee.new({
        :m_id => subscriber_id,
        :rel_code => "self",
        :ben_stat => "active",
        :emp_state => "active",
        :coverage_start => extract_enrollee_start(sub_node),
        :pre_amt => extract_enrollee_premium(sub_node)
      })
      policy.save!
    end

    def persist
      policy = Policy.create!(
        :plan => @plan,
        :eg_id => extract_enrollment_group_id(@policy_node),
        :pre_amt_tot => extract_pre_amt_tot,
        :tot_res_amt => extract_tot_res_amt
      )
      build_subscriber(policy)
      other_enrollees = @policy_node.enrollees.reject { |en| en.subscriber? }
      other_enrollees.each do |en|
        build_enrollee(policy, en)
      end
      true
    end
  end
end
