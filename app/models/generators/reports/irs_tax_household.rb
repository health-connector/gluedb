module Generators::Reports  
  class IrsTaxHousehold

    attr_accessor :primary, :spouse, :dependents

    def initialize(tax_household, policies)
      @tax_household = tax_household
      @policies = policies
      @primary = nil
      @spouse = nil
      @dependents = []
    end

    def build
      people = @tax_household.tax_household_members.flat_map(&:family_member).flat_map(&:person).uniq
      if @tax_household.tax_household_members.count != people.count
        raise 'duplicate tax household members'
      end

      tax_filers = @tax_household.tax_household_members.select{ |member|
        member.tax_filing_status == 'tax_filer'
      }

      return if tax_filers.empty?
      @primary = tax_filers.first

      if tax_filers.count > 1
        raise 'more than two tax_filers' if tax_filers.count > 2
        raise 'tax_filing_together set to false' if tax_filers.any? {|filer| !filer.tax_filing_together? }

        @primary = tax_filers.detect{|tax_filer| tax_filer.family_member == @tax_household.household.family.primary_applicant}
        if @primary.blank?
          @primary = tax_filers.detect{|tax_filer| policies_by_subscriber.keys.include?(tax_filer.family_member.person)}
        end

        if @primary
          @spouse = tax_filers.detect{|filer| filer != @primary}
        end
      end

      identify_spouse if @spouse.nil?
      @dependents = tax_dependents
    end

    def identify_spouse
      non_filers.each do |non_filer|
        @policies.each { |pol| 
          if spouse_rel_code?(pol, non_filer)
            @spouse = non_filer
            break
          end
        }
        break if @spouse
      end
    end

    def spouse_rel_code?(pol, tax_member)
      person = tax_member.family_member.person
      enrollee = pol.enrollees.detect{|enrollee| enrollee.person == person}
      rel_code = enrollee.rel_code.downcase
      if rel_code == 'spouse'
        true
      elsif rel_code == 'self'
        spouse = pol.enrollees.detect{|enrollee| enrollee.rel_code == 'spouse'}
        if spouse.nil? || @primary.nil?
          false
        else
          spouse.person == @primary.family_member.person ? true : false
        end
      end
    end

    def tax_dependents
      children = []
      children = non_filers
      children.reject!{ |child| child == @spouse } if @spouse

      children.compact + @tax_household.tax_household_members.select{ |member|
        member.tax_filing_status == 'dependent'
      }
    end

    def non_filers
      @tax_household.tax_household_members.select{ |member|
        member.tax_filing_status == 'non_filer'
      }
    end

    def policies_by_subscriber
      @policies.inject({}) do |hash, policy|
        (hash[policy.subscriber.person] ||= []) << policy.id
        hash
      end
    end

  end
end