class BulkTerminatesController < ApplicationController
  load_and_authorize_resource :class => "VocabUpload"

  def new

  end

  def create
    file = params[:bulk_terminates_file]

    paramfile = file.original_filename
    dl_name = File.basename(paramfile, File.extname(paramfile)) + "_status.csv"

    requests = CsvRequest.create_many(file.read.force_encoding('utf-8'), current_user.email)
    end_coverage = EndCoverage.new(EndCoverageAction)

    out_stream = CSV.generate do |csv|
      csv << ["Last Name", "First Name", "Middle Name", "Policy id", "End Date", "Subscriber id", "errors", "details"]
      requests.each do |csv_request|
        error_logger = BulkCancelTerms::Csv.new(csv_request, csv)
        request = EndCoverageRequest.for_bulk_terminates(csv_request.to_hash, current_user.email)
        end_coverage.execute_csv(request,error_logger)
      end
    end

    send_data out_stream, :filename => dl_name, :type => "text/csv", :disposition => "attachment"
  end

end
