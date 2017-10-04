module PoliciesHelper

  def show_1095A_document_button?(policy)
    if policy.subscriber
      Time.now.in_time_zone('Eastern Time (US & Canada)').year > policy.subscriber.coverage_start.year
    else
      false
    end
  end

  def disable_radio_button?(policy)
    ["canceled", "carrier_canceled"].include? policy.aasm_state
  end
end
