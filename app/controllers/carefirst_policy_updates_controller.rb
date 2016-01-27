class CarefirstPolicyUpdatesController < ApplicationController

  def create
    @carefirst_policy_update = params[:carefirst_policy_update]

    status_map = {
      'canceled' => 'carrier_canceled',
      'terminated' => 'carrier_terminated',
      'effectuated' => 'effectuated',
      'submitted' => 'submitted'
    }

    request_model = {
      carrier_id: Carrier.where(:abbrev => "GHMSI").first.id,
      policy_id: @carefirst_policy_update[:glue_policy_id],
      status: status_map[@carefirst_policy_update[:status]],
      begin_date: @carefirst_policy_update[:begin_date],
      end_date: @carefirst_policy_update[:end_date],
      subscriber_id: @carefirst_policy_update[:subscriber_hbx_id],
      enrolled_count: @carefirst_policy_update[:enrolled_count],
      hios_plan_id: @carefirst_policy_update[:hios_plan_id],
      file_name: @carefirst_policy_update[:file_name],
      batch_id: @carefirst_policy_update[:batch_id],
      batch_index: @carefirst_policy_update[:batch_index],
      submitted_by: @carefirst_policy_update[:submitted_by],
      attestation_date: @carefirst_policy_update[:attestation_date],
      body: @carefirst_policy_update[:body]
    }

    UpdatePolicyStatus.new(Policy).execute(request_model, Listeners::CarefirstPolicyUpdate.new(self))
  end

  def respond_to_success
    respond_to do |format|
      format.json { render :nothing => true, :status => 202 }
    end
  end

  def respond_to_failure(errors)
    respond_to do |format|
      format.json { render :json => errors.to_json, :status => 422 }
    end
  end

  def upload_csv
    file = params[:policy_status_file]

    connection = Bunny.new(ExchangeInformation.amqp_uri, :heartbeat => 10)
    connection.start
    exchange = connection.create_channel.default_exchange

    exchange.publish(
      file.read.force_encoding('utf-8'),
      :routing_key => "hbx.csv_batch_process",
      :headers => {
        :file_name => download_filename(file),
        :csv_queue => "hbx.cf_update_policy",
        :submitted_by => current_user.email
      }
    )
    connection.close
  end

  private

  def download_filename(file)
    fname = file.original_filename
    File.basename(fname,File.extname(fname)) + "_status.csv"
  end
end












