class RenewalsGenerator

  def initialize(type = 'uqhp')
    @count = 0
    @type = type
    @logger = Logger.new("#{Rails.root}/log/dec_renewals.log")
  end

  def run
    policies = Policy.active_renewal_policies

    uqhp_policies = policies.without_aptc
    qhp_policies = policies.with_aptc

    policies = (@type == 'qhp' ? policies.with_aptc : policies.without_aptc)
    member_ids = policies.map{|x| x.subscriber.m_id}.uniq

    set = 1 
    lower_bound = 0
    batch_size  = 200
    upper_bound = 199

    while true
      folder_number = prepend_zeros(set.to_s, 6)
      @folder_name = "DCHBX_#{Date.today.strftime('%d_%m_%Y')}_#{folder_number}"
      Dir.mkdir "#{Rails.root.to_s}/#{@type}_pdf_reports/#{@folder_name}"

      member_ids[lower_bound..upper_bound].each do |m_id|
        member_policies = policies.by_member_id(m_id)
        if @type == 'qhp'
          member_policies += uqhp_policies.by_member_id(m_id).select{|x| x.plan.coverage_type == 'dental'}
        else
          matched = qhp_policies.by_member_id(m_id)
          if matched.count > 0
            matched += member_policies.select{|x| x.plan.coverage_type == 'dental'} 
            policy_hash = matched.inject({}) do |data, policy|
              data["#{policy.subscriber.m_id}-#{policy.plan.hios_plan_id}"] = policy
              data
            end
            non_duplicate_policies = policy_hash.values
            dentals = group_policies_for_noticies(non_duplicate_policies).inject([]) do |data, policies|
              data << (policies[0].nil? ? nil : policies[1])
            end   
            if dentals && dentals.compact.size > 0
              member_policies = member_policies.uniq - dentals.compact.uniq
            end
          end
        end

        policy_hash = member_policies.inject({}) do |data, policy|
          data["#{policy.subscriber.m_id}-#{policy.plan.hios_plan_id}"] = policy
          data
        end

        non_duplicate_policies = policy_hash.values
        group_policies_for_noticies(non_duplicate_policies).each do |policies|
          begin
            next if (@type == 'qhp') && policies[0].nil?
            notice = build_input_object(policies)
            write_report(notice)
          rescue Exception => e
            @logger.info "#{policies.inspect}-----#{e.inspect}"
          end
        end
      end

      lower_bound = upper_bound + 1
      upper_bound += batch_size
      set += 1
      break if member_ids[lower_bound..upper_bound].nil?
    end
  end

  def build_input_object(policies)
    health, dental = policies
    notice = PdfTemplates::NoticeInput.new
    base_policy = health || dental

    if base_policy.subscriber.nil?
      raise 'no subscriber present' 
    end

    primary = base_policy.subscriber.person
    members = base_policy.enrollees_sans_subscriber.map{|enrollee| enrollee.person.name_full}

    notice.primary_name = primary.name_full
    notice.primary_identifier = primary.authority_member.hbx_member_id
    @hbx_member_id = notice.primary_identifier
    if primary.addresses.empty?
      raise 'subscriber address empty'
    end

    append_address(primary, notice)
    notice.covered_individuals = members
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

  private

  def group_policies_for_noticies(policies)
    health_policies = policies.select{|x| x.plan.coverage_type == 'health'}
    dental_policies = policies.select{|x| x.plan.coverage_type == 'dental'}
    if health_policies.empty?
      return dental_policies.inject([]) do |data, dental|
        data << [nil , dental]
      end
    else
      policy_groups = health_policies.inject([]) do |data, health|
        member_ids = health.enrollees.map { |x| x.m_id }.sort
        matching_dentail = nil

        dental_policies.each do |dental|
          if dental.enrollees.map { |e| e.m_id }.sort == member_ids
            matching_dentail = dental
            break
          end
        end

        dental_policies.delete(matching_dentail)
        data << [health, matching_dentail]
      end
      policy_groups + dental_policies.map{|dental| [nil, dental]}
    end
  end

  def write_report(notice)
    pdf = Generators::Reports::Renewals.new(notice, @type)
    file_name = generate_file_name
    pdf_file_name = "#{Rails.root.to_s}/#{@type}_pdf_reports/#{@folder_name}/#{file_name}.pdf"
    pdf.render_file(pdf_file_name)
  end

  def generate_file_name
    @count += 1
    sequential_number = @count.to_s
    sequential_number = prepend_zeros(sequential_number, 6)
    if @type == 'qhp'
      "#{sequential_number}_HBX_03_#{@hbx_member_id}_ManualSR7"
    else
      "#{sequential_number}_HBX_03_#{@hbx_member_id}_ManualSR8"
    end
  end

  def prepend_zeros(number, n)
    number = number.to_s
    (n - number.to_s.size).times do
      number = number.prepend('0')
    end
    return number
  end
end
