class GenerateTransforms

  def initialize 
  @reason_codes = [
    "initial",
    "auto_renew",
    "active_renew",
    "audit",
    "reinstate_enrollment",
    "terminate_enrollment"
    ]
  end

  def generate_transform
    begin 
      system("rm -rf source_xmls > /dev/null")
      Dir.mkdir("source_xmls") 
      policies = ENV['eg_ids'].split(',').uniq
      policies.each do |eg_id|
        policy = Policy.where(eg_id: eg_id).first
        if policy.present? && ENV['reason_code'].in?(@reason_codes)
          event_type = "urn:openhbx:terms:v1:enrollment##{ENV['reason_code']}"
          affected_members = []      
          policy.enrollees.each{|en| affected_members << BusinessProcesses::AffectedMember.new({:policy => policy, :member_id => en.m_id})}
          tid = generate_transaction_id
          cv_render = render_cv(affected_members,policy,event_type,tid) 
          file_name = "#{policy.eg_id}_#{event_type.split('#').last}.xml"
          f = File.open(file_name,"w")
          f.puts(cv_render) if cv_render
          f.close
          puts "#{file_name} has been generated" unless Rails.env.test?
          system("mv #{file_name} source_xmls")
        else
          puts "#{eg_id} Policy id is not found or #{ENV['reason_code']} is not correct reason code" unless Rails.env.test?
        end
      end
    rescue Exception => e
      puts e.message unless Rails.env.test?
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