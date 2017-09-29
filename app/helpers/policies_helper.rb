module PoliciesHelper

  def show_1095A_document_button?(policy)
    if policy.subscriber
      [2014, 2015, 2016].include? policy.subscriber.coverage_start.year
    else
      false
    end
  end
end
