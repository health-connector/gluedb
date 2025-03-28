module ExternalEvents
  class ExternalPolicyMemberAdd
    attr_reader :policy_node
    attr_reader :added_member_ids
    attr_reader :policy_to_update

    include Handlers::EnrollmentEventXmlHelper

    # p_node : Openhbx::Cv2::Policy
    def initialize(pol_to_change, p_node, added_member_ids)
      @policy_node = p_node
      @added_member_ids = added_member_ids
      @policy_to_update = pol_to_change
    end

    def extract_pre_amt_tot
      p_enrollment = Maybe.new(@policy_node).policy_enrollment.value
      return 0.00 if p_enrollment.blank?
      BigDecimal.new(Maybe.new(p_enrollment).premium_total_amount.strip.value)
    end

    def extract_tot_res_amt
      p_enrollment = Maybe.new(@policy_node).policy_enrollment.value
      return 0.00 if p_enrollment.blank?
      BigDecimal.new(Maybe.new(p_enrollment).total_responsible_amount.strip.value)
    end

    def extract_enrollee_premium(enrollee)
      pre_string = Maybe.new(enrollee).benefit.premium_amount.value
      return 0.00 if pre_string.blank?
      BigDecimal.new(pre_string)
    end

    def extract_rating_details
      r_area = Maybe.new(@policy_node).policy_enrollment.rating_area.value
      c_plan_id = Maybe.new(@policy_node).policy_enrollment.plan.alias_ids.first.value
      potential_data = [
       [:rating_area, r_area],
       [:carrier_specific_plan_id, c_plan_id]
      ]
      potential_data.inject({}) do |acc, pair|
        unless pair.last.blank?
          acc[pair.first] = pair.last
        end
        acc
      end
    end

    def extract_other_financials
      p_enrollment = Maybe.new(@policy_node).policy_enrollment.value
      return({}) if p_enrollment.blank?
      if p_enrollment.shop_market
        tot_emp_res_amt = Maybe.new(p_enrollment).shop_market.total_employer_responsible_amount.strip.value
        composite_rating_tier_name = Maybe.new(p_enrollment).shop_market.composite_rating_tier_name.strip.value
        employer = find_employer(@policy_node)
        potential_data = [
          [:employer, employer],
          [:composite_rating_tier, composite_rating_tier_name],
          [:tot_emp_res_amt, tot_emp_res_amt]
        ]
        potential_data.inject({}) do |acc, pair|
          case pair.first
          when :employer
            acc[pair.first] = pair.last
          when :tot_emp_res_amt
            unless pair.last.blank?
              acc[pair.first] = BigDecimal.new(pair.last)
            end
          else
            unless pair.last.blank?
              acc[pair.first] = pair.last
            end
          end
          acc
        end
      else
        applied_aptc_val = Maybe.new(p_enrollment).individual_market.applied_aptc_amount.strip.value
        return({}) if applied_aptc_val.blank?
        {
          :applied_aptc => BigDecimal.new(applied_aptc_val)
        }
      end
    end

    def extract_rel_from_me(rel)
      simple_relationship = Maybe.new(rel).relationship_uri.strip.split("#").last.downcase.value
      case simple_relationship
      when "life_partner", "domestic_partner"
        "life partner"
      when "spouse"
        "spouse"
      when "ward"
        "ward"
      else
        "child"
      end
    end

    def extract_rel_from_sub(rel)
      simple_relationship = Maybe.new(rel).relationship_uri.strip.split("#").last.downcase.value
      case simple_relationship
      when "life_partner", "domestic_partner"
        "life partner"
      when "spouse"
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
      return extract_rel_from_sub(sub_to_me.first) if sub_to_me.any?
      "child"
    end

    def build_enrollee(policy, enrollee_node)
      member_id = extract_member_id(enrollee_node)
      enrollee = policy.enrollees.detect { |en| en.m_id == member_id }

      if @added_member_ids.include?(member_id)
        if is_reinstate_canceled_policy && enrollee
          enrollee.assign_attributes({
            :ben_stat => policy.is_cobra? ?  "cobra" : "active",
            :emp_stat => "active",
            :coverage_start => extract_enrollee_start(enrollee_node),
            :pre_amt => extract_enrollee_premium(enrollee_node),
            :coverage_end => nil
          })
          enrollee.save!
        else
          policy.enrollees << Enrollee.new({
            :m_id => member_id,
            :rel_code => extract_rel_code(enrollee_node),
            :ben_stat => policy.is_cobra? ?  "cobra" : "active",
            :emp_stat => "active",
            :coverage_start => extract_enrollee_start(enrollee_node),
            :pre_amt => extract_enrollee_premium(enrollee_node)
          })
        end
      else
        if enrollee
          enrollee.pre_amt = extract_enrollee_premium(enrollee_node)
          enrollee.save!
        end
      end
      policy.save!
    end

    def is_reinstate_canceled_policy
      @policy_node.is_reinstate_canceled_policy
    end

    def subscriber_id
      @subscriber_id ||= begin
        sub_node = extract_subscriber(@policy_node)
        extract_member_id(sub_node)
      end
    end

    def persist
      pol = policy_to_update
      pol.update_attributes!({
        :pre_amt_tot => extract_pre_amt_tot,
        :tot_res_amt => extract_tot_res_amt
      }.merge(extract_other_financials).merge(extract_rating_details))
      pol = Policy.find(pol._id)
      @policy_node.enrollees.each do |en|
        build_enrollee(pol, en)
      end
      true
    end
  end
end
