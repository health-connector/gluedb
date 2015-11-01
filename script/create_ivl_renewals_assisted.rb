  require File.join(Rails.root, "script/queries/policy_id_generator")
require 'pry'

policy_ids = [29796,29809]

   # File.readlines('renewal_ids_phase1_assisted_health_kaiser.txt').map do |line|
   #   policy_ids.push(line.to_i)
   # end

puts "#{policy_ids.count} CVs to generate."


pols_mems_ids = []

pols_ids = []

pols_mems = Policy.where(PolicyStatus::Active.as_of(Date.new(2015,12,31)).query).where({ "_id" => { "$in" => policy_ids }})
pols = Policy.where(PolicyStatus::Active.as_of(Date.new(2015,12,31)).query).where({ "_id" => { "$in" => policy_ids }}).no_timeout

m_ids = []

pols_mems.each do |mpol|
  pols_mems_ids.push(mpol._id)
  mpol.enrollees.each do |en|
    m_ids << en.m_id
  end
end

pols.each do |pol|
  pols_ids.push(pol._id)
end

all_not_pulled = (pols_ids + pols_mems_ids).uniq

puts "pols_mems did not pull in #{policy_ids - pols_mems_ids}"
puts "pols did not pull in #{policy_ids - pols_ids}"

member_repo = Caches::MemberCache.new(m_ids)
calc = Premiums::PolicyCalculator.new(member_repo)
Caches::MongoidCache.allocate(Plan)
Caches::MongoidCache.allocate(Carrier)

polgen = PolicyIdGenerator.new(policy_ids.count)

FileUtils.rm_rf(Dir.glob('renewals/*'))

def change_variant(policy)
  hios_no_variant = policy.plan.hios_plan_id.chomp("-01").chomp("-02").chomp("-03").chomp("-04").chomp("-05").chomp("-06")
  plan_choices = Plan.where(:hios_base_id => hios_no_variant).where(:year => 2016).to_a
  if policy.plan.metal_level.downcase == "silver"
    variant = choose_variant(policy.csr_amt)
    plan_choices.each do |plan|
      if plan.csr_variant_id == variant # variant matcher
        return plan
      else
        next
      end # Ends variant matcher
    end # Ends plan_choices.each
  else
    return policy.plan
  end # Ends policy.csr_amt != nil...
end

def choose_variant(csr_amt)
  if csr_amt.to_f == 73
    return variant = "04"
  elsif csr_amt.to_f == 87
    return variant = "05"
  elsif csr_amt.to_f == 94
    return variant = "06"
  elsif csr_amt.to_f == 100
    return variant = "02"
  else
    return variant = "01"
  end
end

  def get_maximum_aptc(policy,year)
    policy.aptc_maximums.detect do |aptc_maximum|
      aptc_maximum.start_on.year == year
    end
  end

  def get_csr_variant(policy,year)
    policy.cost_sharing_variants.detect do |cost_sharing_variant|
      cost_sharing_variant.start_on.year == year
    end
  end

  def get_aptc_credits(policy)
    policy.aptc_credits.detect do |aptc_credit|
      aptc_credit.start_on.year == 2016
    end
  end

pols.each do |pol|
  if pol.subscriber.coverage_end.blank?
    sub_member = member_repo.lookup(pol.subscriber.m_id)
    authority_member = sub_member.person.authority_member
    old_p_id = pol._id
    if authority_member.blank?
      puts "No authority member for: #{pol.subscriber.m_id}"
    else
      #if (sub_member.person.authority_member.hbx_member_id == pol.subscriber.m_id)
        begin
          r_pol = pol.clone_for_renewal(Date.new(2016,1,1))
          maximum_aptc = get_maximum_aptc(pol,2016)
          if maximum_aptc.present?
          r_pol.allocated_aptc = maximum_aptc.max_aptc
          r_pol.elected_aptc = r_pol.allocated_aptc * maximum_aptc.aptc_percent
          else
            r_pol.allocated_aptc = 0
            r_pol.elected_aptc = 0
          end

          aptc_credit = get_aptc_credits(pol)
          if aptc_credit.present?
            r_pol.applied_aptc = aptc_credit.aptc
          else
            r_pol.applied_aptc = 0
          end

          csr_variant = get_csr_variant(pol,2016)
          if csr_variant.present?
            r_pol.csr_amt = csr_variant.percent
          else
            r_pol.csr_amt = 0
          end

          r_pol.plan = change_variant(r_pol)
          calc.apply_calculations(r_pol)
          p_id = polgen.get_id
          out_file = File.open("renewals/#{old_p_id}_#{p_id}.xml",'w')
          member_ids = r_pol.enrollees.map(&:m_id)
          r_pol.eg_id = p_id.to_s
          ms = CanonicalVocabulary::MaintenanceSerializer.new(r_pol,"change", "renewal", member_ids, member_ids, {:member_repo => member_repo})
          out_file.print(ms.serialize)
          out_file.close
        rescue Exception=>e
          puts "#{pol._id} did not generate - #{pol.hios_plan_id} - #{pol.plan.metal_level} " + e.message
          # puts pol.plan.hios_plan_id
          # puts pol.applied_aptc
          # puts ""
        end
      #end
    end
  end
end

Caches::MongoidCache.release(Plan)
Caches::MongoidCache.release(Carrier)