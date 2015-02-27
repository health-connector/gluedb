module PdfTemplates
  class IrsGroup
    include Virtus.model

    attribute :calender_year, Integer
    attribute :identification_num, String
    attribute :households, Array[PdfTemplates::Household]
    attribute :insurance_policies, Array[PdfTemplates::IrsNoticeInput]
    attribute :policies, Array[Policy]

    def coverage_ids
      pol_ids = []
      households.each do |h|
        h.irs_households.each { |i| pol_ids += i.policy_ids }
      end
      pol_ids.flatten.uniq
    end

    def coverage_months(duration_months)
      (1..duration_months).each do |month|
      end
    end

    def irs_households_for_duration(months)
      active_household.irs_households.select do |irs_household| 
        had_coverage(irs_household, months)
      end
    end

    def had_coverage(irs_household, months)
      (1..months).each do |month|
        policies = policies_for_month(month).map(&:id)
        if (irs_household.policy_ids & policies).any?
          return true
        end
      end
      false
    end

    def active_household
      households[0]
    end

    def household_for_month(month)
      if households.count > 1
      else
        households[0]
      end
    end

    def policies_for_month(month)
      end_of_month = Date.new(calender_year, month, 1).end_of_month

      pols = []
      policies.each do |pol|
        if pol.subscriber.coverage_start < end_of_month          
          start_date = pol.policy_start
          end_date = pol.policy_end.blank? ? pol.coverage_period_end : pol.policy_end
          pols << pol if (start_date.month..end_date.month).include?(month)
        end
      end

      pols.uniq
    end

    def irs_household_coverage_as_of(irs_household, month)
      policies = policies_for_month(month).map(&:id)
      coverages = irs_household.policy_ids & policies

      coverages.inject([]) do |data, coverage|
        data << insurance_policies.detect{|ins_pol| ins_pol.policy_id.to_i == coverage }
      end
    end

    def irs_tax_households(month)
      policies = policies_for_month(month).map(&:id)
      household = household_for_month(month)
      household.irs_households.select{|x| (x.policy_ids & policies).any? }
    end
  end
end