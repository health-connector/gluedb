
class GenerateTransforms

  def initialize 
  @reason_codes = [
    "initial",
    "auto_renew",
    "active_renew",
    "active_renew_member_add",
    "audit",
    "change_member_identifier",
    "change_member_address",
    "change_member_communication_numbers",
    "change_member_handicap_status",
    "change_financial_assistance",
    "change_product",
    "change_product_member_add",
    "change_reenroll",
    "reinstate_enrollment",
    "reinstate_member",
    "cancel_enrollment",
    "terminate_enrollment",
    "change_member_add",
    "change_member_terminate",
    "change_member_name_deprecated",
    "change_member_name_or_demographic",
    "change_member_demographic_deprecated",
    "change_relationship"
    ]
  end

  def begin_transform
    `rm -rf source_xmls`
    `mkdir source_xmls`
    if ENV['reason_code'].in?(@reason_codes)
      reason_code = "urn:openhbx:terms:v1:enrollment##{ENV['reason_code']}" 
    else
      return puts 'Could not find a matching reason code'
    end
    generate_transform(reason_code)
  end
  
  def generate_transform(reason_code)
    policies = ENV['eg_ids'].split(',').map do |policy|
       Policy.where(:eg_id => {"$in" => [policy]}).first
    end

    policies.each do |policy|
      affected_members = []      
      policy.enrollees.each{|en| affected_members << BusinessProcesses::AffectedMember.new({:policy => policy, :member_id => en.m_id})}
      event_type = reason_code
      tid = generate_transaction_id
      cv_render = render_cv(affected_members,policy,event_type,tid)
      file_name = "#{policy.eg_id}_#{reason_code.split('#').last}.xml"
      f = File.open(file_name,"w")
      f.puts(cv_render)
      f.close
      move_files(file_name)
    end

  end

  def move_files(file_name)
    `mv #{file_name} source_xmls`
    if File.exist?(Rails.root.join('source_xmls', file_name))
      `zip -r source_xmls.zip source_xmls`
      puts "#{file_name} has been generated"
    else 
      puts "#{file_name} has not been generated please try again"
    end
  end

  def generate_transaction_id
    transaction_id ||= begin
                          ran = Random.new
                          current_time = Time.now.utc
                          reference_number_base = current_time.strftime("%Y%m%d%H%M%S") + current_time.usec.to_s[0..2]
                          reference_number_base + sprintf("%05i", ran.rand(65535))
                        end
    transaction_id
  end

  def render_cv(affected_members,policy,event_kind,transaction_id)

    render_result = ApplicationController.new.render_to_string(
          :layout => "enrollment_event",
          :partial => "enrollment_events/enrollment_event",
          :format => :xml,
          :locals => {
            :affected_members => affected_members,
            :policy => policy,
            :enrollees => policy.enrollees,
            :event_type => event_kind,
            :transaction_id => transaction_id
          })
  end

end

