
class GenerateTransforms
  
  def generate_transforms
    system("rm -rf source_xmls > /dev/null")
    Dir.mkdir("source_xmls")
    cv21s = GenerateCv21s.new(ENV['reason_code']).run

  end
end


class GenerateCv21s 

  def initialize(reason_code)
    @reason_code =  "urn:openhbx:terms:v1:enrollment##{reason_code}"
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

  def run 
    policies = ENV['eg_ids'].split(',').map do |policy|
       Policy.where(:eg_id => {"$in" => [policy]}).first
    end

    policies.each do |policy|
      affected_members = []
      policy.enrollees.each{|en| affected_members << BusinessProcesses::AffectedMember.new({:policy => policy, :member_id => en.m_id})}
      event_type = @reason_code
      tid = generate_transaction_id
      cv_render = render_cv(affected_members,policy,event_type,tid)
      f = File.open("#{policy.eg_id}_#{@reason_code.split('#').last}.xml","w")
      f.puts(cv_render)
      f.close
      `mv #{f} source_xmls`
      `zip -r source_xmls.zip source_xmls`
      `bundle exec rails r script/cv_x12_gen.rb -e production`
    end
  end

end
