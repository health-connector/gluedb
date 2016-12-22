module EmployerEvents
  class CarrierFile
    attr_reader :carrier
    attr_reader :buffer
    attr_reader :begin_timestamp
    attr_reader :end_timestamp

    def initialize(carrier)
      @empty = true
      @buffer = StringIO.new
      @begin_timestamp = nil
      @end_timestamp = nil
    end

    def <<(data)
      @empty = false
      @buffer << data
    end

    def update_timestamps(timestamp)
      @begin_timestamp = [@begin_timestamp, timestamp].compact.min
      @end_timestamp = [@end_timestamp, timestamp].compact.max
    end

    def result
      return nil if @empty
      carrier_abbrev = carrier.abbrev.upcase
      header = <<-XMLHEADER
<?xml version="1.0" encoding="UTF-8"?>
<employer_digest_event
        xmlns="http://openhbx.org/api/terms/1.0"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://openhbx.org/api/terms/1.0 organization.xsd">
        <event_name>urn:openhbx:events:v1:employer#digest_period_ended</event_name>
        <resource_instance_uri>
                <id>urn:openhbx:resources:v1:carrier:abbreviation##{carrier_abbrev}</id>
        </resource_instance_uri>
        <body>
                <employer_events>
                        <coverage_period>
                                <begin_datetime>#{@begin_timestamp.iso8601}</begin_datetime>
                                <end_datetime>#{@end_timestamp.iso8601}</end_datetime>
                        </coverage_period>
      XMLHEADER
      trailer = <<-XMLTRAILER
                </employer_events>
        </body>
</employer_digest_event>
      XMLTRAILER
      @buffer << trailer
      header << @buffer.string
      header
    end
  end
end
