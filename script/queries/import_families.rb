path = "/Users/CitadelFirm/Downloads/projects/hbx/RenewalReports_150121233949247.xml"

@@logger = Logger.new("#{Rails.root}/log/family_#{Time.now.utc.iso8601}.log")

begin
  iag = ImportFamilies.new(path)
  iag.run
rescue Exception=>e
  @@logger.info "#{DateTime.now.to_s} class:#{self.class.name} method:#{__method__.to_s}\n"+
                    "message:#{e.message}\n" +
                    "backtrace:#{e.backtrace.inspect}\n"
end
