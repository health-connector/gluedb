module Parsers
  module Edi
    class TransmissionResponse
      attr_reader :parser, :transmitted_at, :sender_id

      def initialize(path, payload)
        @input = payload
        @file_name = File.basename(path)
        @result = Oj.load(@input)
        parse_header
        parse_response
      end

      def valid_header
        isa_seg = @result["ISA"]
        return false unless isa_seg.present?
        return false unless (isa_seg[9].present? && isa_seg[10].present? && isa_seg[6].strip.present?)
        true
      end

      def valid_response
        ta1_seg = @result["TA1s"].first
        return false unless (ta1_seg[1].present? && ta1_seg[2].present? && ta1_seg[3].present? && ta1_seg[4].present?)
        true
      end

      def parse_header
        isa_seg = @result["ISA"]
        result_date = isa_seg[9]
        result_time = isa_seg[10]
        result_dt = "20" + result_date + result_time
        @transmitted_at = DateTime.strptime("20" + result_date + result_time, "%Y%m%d%H%M")
        @sender_id = isa_seg[6].strip
      end

      def parse_response
        ta1_seg = @result["TA1s"].first
        @accepted = ["A", "E"].include?(ta1_seg[4])
        @isa13 = ta1_seg[1]
        @isa09 = ta1_seg[2]
        @isa10 = ta1_seg[3]
      end

      def accepted?
        @accepted
      end

      def persist!
        transmission = Protocols::X12::Transmission.where(
          :isa13 => @isa13,
          :isa08 => @sender_id
        ).first
        if !transmission.nil?
          if accepted? && valid_header && valid_response
            transmission.acknowledge!(@transmitted_at)
          elsif accepted? && (!valid_header || !valid_response)
            transmission.invalid_response!(@transmitted_at)
          else
            transmission.reject!(@transmitted_at)
          end
        end
      end
    end
  end
end
