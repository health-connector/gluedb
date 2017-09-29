module PoliciesHelper

  def show_1095A_document_button?(policy)
    if policy.subscriber
      [2014, 2015, 2016].include? policy.subscriber.coverage_start.year
    else
      false
    end
  end

  def disable_void_radio_button?(policy)
    ["canceled", "carrier_canceled"].include? policy.aasm_state
  end

  def disable_corrected_radio_button?(policy)
    ["canceled", "carrier_canceled"].include? policy.aasm_state
  end
end
