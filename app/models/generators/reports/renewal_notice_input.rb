module Generators::Reports  
  class RenewalNoticeInput

    def create(policies)
      health, dental = policies
      notice = PdfTemplates::NoticeInput.new
      base_policy = health || dental

      if base_policy.subscriber.nil?
        raise 'no subscriber present'
      end

      primary = base_policy.subscriber.person
      members = base_policy.enrollees_sans_subscriber.map{|enrollee| enrollee.person.name_full}
      notice.covered_individuals = members

      notice.primary_name = primary.name_full
      notice.primary_identifier = primary.authority_member.hbx_member_id
      if primary.addresses.empty?
        raise 'subscriber address empty'
      end

      notice = append_address(primary, notice)
      notice = append_health_policy(health, notice) if health
      notice = append_dental_policy(dental, notice) if dental

      return notice
    end

    def append_address(primary, notice)
      primary_address = primary.addresses[0]
      address = PdfTemplates::NoticeAddress.new
      address.street_1 = primary_address.address_1
      address.street_2 = primary_address.address_2
      address.city = primary_address.city
      address.state = primary_address.state
      address.zip = primary_address.zip
      notice.primary_address = address
      notice
    end

    def append_health_policy(health, notice)
      notice.health_plan_name = health.plan.name
      notice.health_premium = health.pre_amt_tot
      if @type == 'qhp'
        notice.health_aptc = health.applied_aptc
        notice.health_responsible_amt = health.tot_res_amt
      end
      notice    
    end

    def append_dental_policy(dental, notice)
      notice.dental_plan_name = dental.plan.name
      notice.dental_premium = dental.pre_amt_tot
      if @type == 'qhp'
        notice.dental_aptc = dental.applied_aptc
        notice.dental_responsible_amt = dental.tot_res_amt
      end
      notice
    end
  end
end