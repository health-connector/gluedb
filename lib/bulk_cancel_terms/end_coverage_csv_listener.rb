module BulkCancelTerms
  class EndCoverageCsvListener
    def initialize(file_name, batch_id, submitted_at, submitted_by)
      @current_data = {}
      @current_row = 0
      @current_listener = nil
      @file_name = file_name
      @batch_id = batch_id
      @submitted_at = submitted_at
      @submitted_by = submitted_by
      @transmission = create_csv_transmission
    end

    def set_current_row(idx, data, req, listener)
      @current_row = idx
      @current_data = data
      @policy = get_policy(req)
      @current_listener = listener
    end

    def no_subscriber_id(details = {})
      @current_listener.no_subscriber_id(details)
    end

    def no_such_policy(details = {})
      @current_listener.no_such_policy(details)
    end

    def policy_inactive(details = {})
      @current_listener.policy_inactive(details)
    end

    def end_date_invalid(details = {})
      @current_listener.end_date_invalid(details)
    end

    def fail(details = {})
      @current_listener.fail(details)
      create_csv_transaction(@current_listener.errors)
    end

    def success(details = {})
      @current_listener.success(details)
      create_csv_transaction
    end

    def create_csv_transaction(errors = [])
      Protocols::Csv::CsvTransaction.create!({
        :body => FileString.new("#{@current_row}.json",JSON.dump(@current_data)),
        :submitted_at => @submitted_at,
        :error_list => errors,
        :batch_index => @current_row,
        :policy => @policy,
        :csv_transmission => @transmission
      })
    end

    def create_csv_transmission
      Protocols::Csv::CsvTransmission.create!({
        :batch_id => @batch_id,
        :file_name => @file_name,
        :submitted_by => @submitted_by
      })
    end

    def get_policy(req)
      Policy.where(:id => req[:policy_id]).first
    end
  end
end
