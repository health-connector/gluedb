module Config::AcaHelper

  def fetch_file_format
    time_stamp = specific_state_time_stamp
    "#{Settings.aca.enrollment_policy_report_name}_#{time_stamp}.csv"
  end

   def specific_state_time_stamp
     Time.now.strftime('%Y_%m_%d_%H_%M_%S')
   end

end
