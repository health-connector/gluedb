module Protocols::Csv
  class CsvTransaction
    include Mongoid::Document
    include Mongoid::Timestamps

    belongs_to :csv_transmission, :class_name => "Protocols::Csv::CsvTransmission", :index => true
    belongs_to :policy, :index => true

    # TODO: Accept this in request
    field :batch_index, type: Integer
    field :error_list, type: Array
    field :submitted_at, type: DateTime

    # TODO: Use a regular set of fields as a hash instead?
    mount_uploader :body, EdiBody

    def rejected?
      error_list.any?
    end

    def transaction_kind
      "CSV Import"
    end

    def ack_nak_processed_at
      nil
    end

    def aasm_state
      rejected? ? "rejected" : "acknowledged"
    end

    def json_body
      json_obj = nil
      begin
        json_obj = Oj.safe_load(body.read)
      rescue Oj::ParseError
      end
      JSON.pretty_generate(json_obj)
    end

    def self.create_transaction(details)
      self.create!(details)
    end
  end
end
