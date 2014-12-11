path = "/Users/CitadelFirm/Downloads/projects/hbx/ApplicantionsGroups_4.xml"

@@logger = Logger.new("#{Rails.root}/log/import_application_groups.log")

begin
  iag = ImportApplicationGroups.new(path)
  iag.run
rescue Exception=>e
  @@logger.info "#{DateTime.now.to_s} class:#{self.class.name} method:#{__method__.to_s}\n"+
                    "message:#{e.message}\n" +
                    "backtrace:#{e.backtrace.inspect}\n"
end
