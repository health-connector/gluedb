module Parsers
  module Edi
    GroupResponse = Struct.new(:isa08, :gs01, :gs03, :gs06, :gs08, :responses)

    class TransactionSetResult
      attr_reader :parser, :transmitted_at, :group_responses, :sender_id

      def initialize(path, payload)
        @input = payload
        @parser = TsrParser.instance.parser
        @file_name = File.basename(path)
        @result = Oj.load(@input)
        parse_header
        parse_responses
      end

      def parse_header
        isa_seg = @result["ISA"]
        result_date = isa_seg[9]
        result_time = isa_seg[10]
        result_dt = "20" + result_date + result_time
        @transmitted_at = DateTime.strptime("20" + result_date + result_time, "%Y%m%d%H%M")
        @sender_id = isa_seg[6].strip
      end

      def parse_responses
        @group_responses = []
        @result["L999s"].each do |l999|
          responses = {}
          ak1_seg = l999["AK1"]
          next if ak1_seg.blank?
          l999["L2000s"].each do |l2000|
            if l2000["AK2"][1] == "834"
              responses[l2000["AK2"][2]] = ["A", "E"].include?(l2000["IK5"][1].strip)
            end
          end
          @group_responses << GroupResponse.new(@sender_id, ak1_seg[1], @result["GS"][2], ak1_seg[2], ak1_seg[3], responses)
        end
      end

      def persist!
        @group_responses.each do |gr|
          found_transmissions = Protocols::X12::Transmission.where(
            :isa08 => gr.isa08,
            :gs01 => gr.gs01,
            :gs06 => gr.gs06,
            :gs08 => gr.gs08,
            :gs03 => gr.gs03
          )
          found_transmissions.each do |found_transmission|
            tses = found_transmission.transaction_set_enrollments
            gr.responses.each_pair do |k, v|
              ts = tses.detect { |ts| ts.st02 == k }
              if !ts.nil?
                ts.aasm_state = v ? "acknowledged" : "rejected"
                ts.ack_nak_processed_at = @transmitted_at
                ts.save!
              end
            end
          end
        end
      end
    end
  end
end
