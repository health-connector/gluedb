class BulkTerminatesController < ApplicationController
  load_and_authorize_resource :class => "VocabUpload"

  def new

  end

  def create
    file = params[:bulk_terminates_file]

    requests = CsvRequest.create_many(file.read.force_encoding('utf-8'), current_user.email)
    end_coverage = EndCoverage.new(EndCoverageAction)

    out_stream = CSV.generate do |csv|
      csv << ["policy_id"]
      requests.each do |csv_request|
        request = EndCoverageRequest.for_bulk_terminates(csv_request.to_hash, current_user.email)
        end_coverage.execute(request)
      end
    end

    flash_message(:success, "Upload successful.")
    redirect_to new_bulk_terminate_path
  end

  def transmistter

  end
end
