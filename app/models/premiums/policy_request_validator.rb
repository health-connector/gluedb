module Premiums
  class PolicyRequestValidator
    class ProxyEnrollee
       attr_reader :rel_code
       attr_reader :expected_pre_amt
       attr_reader :coverage_start
       attr_reader :member

       attr_accessor :pre_amt

       def initialize(props, listener)
         @rel_code = props[:rel_code]
         @expected_pre_amt = props[:pre_amt] || 0.00
         self.coverage_start = props[:coverage_start]
         @member = props[:member]
         @listener = listener
         @valid = true
       end

       def coverage_start=(val)
         @coverage_start = val.kind_of?(String) ? Date.parse(val) : val
       end

       def reference_premium_for(plan, rate_date)
         plan.rate(rate_date, coverage_start, member.dob).amount
       end

       def subscriber?
         rel_code == 'self'
       end

       def pre_amt=(val)
         unless @expected_pre_amt.to_f == val.to_f
           @listener.invalid_member_premium(:expected => @expected_pre_amt.to_f, :calculated => val.to_f)
           @valid = false
         end
         @pre_amt = val
       end

       def valid?
         @valid
       end
    end

    class ProxyPolicy
      attr_reader :employer
      attr_reader :plan
      attr_reader :subscriber
      attr_reader :enrollees
      attr_reader :tot_emp_res_amt
      attr_reader :pre_amt_tot
      attr_reader :applied_aptc

      def initialize(enrollees, plan, employer, props, listener)
        @listener = listener
        @plan = plan
        @employer = employer
        @enrollees = enrollees.map { |en| ProxyEnrollee.new(en, listener) }
        @subscriber = @enrollees.detect { |en| en.subscriber? }
        @expected_pre_amt_tot = props[:pre_amt_tot] || 0.00
        @expected_tot_res_amt = props[:tot_res_amt] || 0.00
        @applied_aptc = props[:applied_aptc] || 0.00
        @expected_tot_emp_res_amt = props[:tot_emp_res_amt] || 0.00
        @valid = true
      end

      def employer_id
        @employer.id
      end

      def is_shop?
        !@employer.blank?
      end

      def valid?
        @valid && (@enrollees.all?(&:valid?))
      end

      def pre_amt_tot=(val)
         unless @expected_pre_amt_tot.to_f == val.to_f
           @listener.invalid_premium_total(:expected => @expected_pre_amt_tot.to_f, :calculated => val.to_f)
           @valid = false
         end
        @pre_amt_tot = val
      end

      def tot_emp_res_amt=(val)
         unless @expected_tot_emp_res_amt.to_f == val.to_f
           @listener.invalid_employer_contribution(:expected => @expected_tot_emp_res_amt.to_f, :calculated => val.to_f)
           @valid = false
         end
        @tot_emp_res_amt = val
      end

      def tot_res_amt=(val)
         unless @expected_tot_res_amt.to_f == val.to_f
           @listener.invalid_responsible_total(:expected => @expected_tot_res_amt.to_f, :calculated => val.to_f)
           @valid = false
         end
        @tot_res_amt = val
      end
    end

    def validate(request, listener)
      failed = false
      hios_id = request[:hios_id]
      plan_year = request[:plan_year]
      enrollees = request[:enrollees]
      employer_fein = request[:employer_fein]
      plan = Plan.find_by_hios_id_and_year(hios_id, plan_year)
      employer = nil
      return false if plan.blank?
      if !employer_fein.blank?
        employer = Employer.find_for_fein(employer_fein)
        if employer.blank?
          return false 
        end
      end
      working_enrollees = enrollees.map do |wen|
        new_en = wen.dup
        new_en[:member] = OpenStruct.new(new_en[:member])
        new_en
      end
      fake_policy = ProxyPolicy.new(
        working_enrollees,
        plan,
        employer,
        request,
        listener
      )
      pc = Premiums::PolicyCalculator.new
      pc.apply_calculations(fake_policy)
      fake_policy.valid?
    end
  end
end
