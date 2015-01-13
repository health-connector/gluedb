module CanonicalVocabulary
  module Renewals
    class RenewalReportRowBuilder 
      include RenewalBuilder

      attr_reader :data_set

      def initialize(application_group, primary)
        @data_set = []
        @application_group = application_group
        @primary = primary
      end

      def append_integrated_case_number
        @data_set << @application_group.e_case_id.split('#')[1]
      end

      def append_name_of(member)
        @data_set << member.person.name_first
        @data_set << member.person.name_last
      end

      def append_notice_date(notice_date)
        @data_set << notice_date
      end

      def append_household_address
        address = @primary.person.addresses[0]
        @data_set << address.address_line_1
        @data_set << address.address_line_2
        append_blank # Apt
        @data_set << address.location_city_name
        @data_set << address.location_state_code
        @data_set << address.location_postal_code
      end

      def append_aptc
        append_blank
      end

      def append_response_date(response_date)
        @data_set << response_date
      end

      def append_policy(policy)
        if policy.current.blank?
          3.times{|i| append_blank }
        else
          @data_set << policy.current.plan_name
          @data_set << policy.current.future_plan_name
          @data_set << policy.current.quoted_premium
        end
      end

      def append_post_aptc_premium
        append_blank
      end

      def append_financials
        @data_set << @application_group.yearly_income("2014")
        append_blank 
        @data_set << @application_group.irs_consent
      end

      def append_age_of(member)
        @data_set << member.age
      end

      def append_residency_of(member)
        @data_set << residency(member)
      end

      def append_citizenship_of(member)
        @data_set << citizenship(member)
      end

      def append_tax_status_of(member)
        @data_set << tax_status(member)
      end

      def append_mec_of(member)
        @data_set << member_mec(member)
      end

      def append_app_group_size
        @data_set << @application_group.applicants.count
      end

      def append_yearwise_income_of(member)
        @data_set << member.income_by_year("2014")
      end

      def append_blank
        @data_set << nil
      end

      def append_incarcerated(member)
        @data_set << incarcerated?(member)
      end
    end
  end
end
