    require 'securerandom'
    require 'csv'
    batch_id = SecureRandom.uuid.gsub("-", "")
    out_file_name = "bulk_term_results.csv"
    file_name = "KevinTest.csv"
    spreadsheet = File.open(file_name, 'r').read
    end_coverage = EndCoverage.new(EndCoverageAction)

    submitted_by = "kevin.wei@dc.gov"
    listener = BulkCancelTerms::EndCoverageCsvListener.new(file_name, batch_id, Time.now, submitted_by )

    CSV.open(out_file_name, "wb") do |csv|
      csv << ["Last Name", "First Name", "Middle Name", "Policy id", "End Date", "Subscriber id", "errors", "details"]
      CSV.parse(spreadsheet, headers: true, header_converters: :symbol, skip_blanks: true).each_with_index do |row, idx|
        csv_req = CsvRequest.new(row, submitted_by)
        request = EndCoverageRequest.for_bulk_terminates(csv_req.to_hash, submitted_by)
        error_logger = BulkCancelTerms::Csv.new(csv_req, csv)
        listener.set_current_row(idx, row.to_hash, request, error_logger)
        end_coverage.execute_csv(request.merge({:transmit => false}),listener)
      end
    end
