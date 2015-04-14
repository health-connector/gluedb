class EndCoverageRequest
  def self.from_form(form_params, current_user)
    details = form_params[:cancel_terminate]
    affected_enrollee_ids = []
    details[:people_attributes].each_pair do |k, v|
      if(v[:include_selected] == '1')
        affected_enrollee_ids << v[:m_id]
      end
    end

    if details[:people_attributes].detect{|k,v|  v[:role] == "self"}[1][:include_selected] == "1"
      affected_enrollee_ids = details[:people_attributes].map{|k,v| v[:m_id]}
    end

    {
      policy_id: form_params[:id],
      affected_enrollee_ids: affected_enrollee_ids,
      coverage_end: details[:benefit_end_date],
      operation: details[:operation],
      reason: details[:reason],
      transmit: details[:transmit] == "1",
      current_user: current_user
    }
  end

  def self.for_mass_silent_cancels(csv_request, current_user)
    unless Policy.where({"_id" => csv_request[:policy_id]}).first.nil?
      policy = Policy.find(csv_request[:policy_id])
      {
        policy_id: csv_request[:policy_id],
        affected_enrollee_ids: [policy.subscriber.m_id], # subscriber triggers everyone
        coverage_end: [policy.subscriber.coverage_start],
        operation: 'cancel',
        reason: 'termination_of_benefits',
        transmit: true,
        current_user: current_user
      }
    else
      policy = {
        policy_id: csv_request[:policy_id],
        affected_enrollee_ids: nil, # subscriber triggers everyone
        coverage_end: nil,
        operation: 'cancel',
        reason: 'termination_of_benefits',
        transmit: true,
        current_user: current_user
      }
    end
  end

  def self.for_bulk_terminates(csv_request, current_user)
    unless Policy.where({"_id" => csv_request[:policy_id]}).first.nil?
      policy = Policy.find(csv_request[:policy_id])
      {
        policy_id: csv_request[:policy_id],
        affected_enrollee_ids: [policy.subscriber.m_id], # subscriber triggers everyone
        coverage_end: csv_request[:end_date],
        operation: 'terminate',
        reason: 'termination_of_benefits',
        transmit: true,
        current_user: current_user
      }
    else
      policy = {
        policy_id: csv_request[:policy_id],
        affected_enrollee_ids: nil, # subscriber triggers everyone
        coverage_end: csv_request[:end_date],
        operation: 'terminate',
        reason: 'termination_of_benefits',
        transmit: true,
        current_user: current_user
      }
    end

  end
end
