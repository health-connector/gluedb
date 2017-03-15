require 'csv'

health_plans = Plan.where(:coverage_type => "health").map(&:id)

policies = Policy.where(:employer_id => nil, :plan_id => {"$in" => health_plans})

apr_term = 0
may_term = 0
jun_term = 0
jul_term = 0
aug_term = 0
sep_term = 0
oct_term = 0
nov_term = 0
dec_term = 0
jan_term = 0
feb_term = 0
mar_term = 0

apr_cancel = 0
may_cancel = 0
jun_cancel = 0
jul_cancel = 0
aug_cancel = 0
sep_cancel = 0
oct_cancel = 0
nov_cancel = 0
dec_cancel = 0
jan_cancel = 0
feb_cancel = 0
mar_cancel = 0

apr_reinstate = 0
may_reinstate = 0
jun_reinstate = 0
jul_reinstate = 0
aug_reinstate = 0
sep_reinstate = 0
oct_reinstate = 0
nov_reinstate = 0
dec_reinstate = 0
jan_reinstate = 0
feb_reinstate = 0
mar_reinstate = 0

date_cutoff = ((DateTime.now+1.month).beginning_of_month)-1.year

def find_transaction_type(edi)
  edi_array = edi.split("~")
  reinstate_check = is_reinstate(edi_array)
  termination_check = is_term(edi_array)
  cancel_check = is_cancel(edi_array)
  if reinstate_check == true && termination_check == false && cancel_check == false
    return "reinstate"
  elsif reinstate_check == false && termination_check == true && cancel_check == false
    return "termination"
  elsif reinstate_check == false && termination_check == false && cancel_check == true
    return "cancel"
  elsif reinstate_check == false && termination_check == false && cancel_check == false
    return "other"
  end
end

def is_reinstate(edi_array)
  relevant_segments = edi_array.select{|seg| /HD/.match(seg)}
  if relevant_segments.any?{|seg| /025/.match(seg)}
    return true
  else
    return false
  end
end

def is_term(edi_array)
  relevant_segments = edi_array.select{|seg| /TERM/.match(seg)}
  if relevant_segments.present?
    return true
  else
    return false
  end
end

def is_cancel(edi_array)
  relevant_segments = edi_array.select{|seg| /CANCEL/.match(seg)}
  if relevant_segments.present?
    return true
  else
    return false
  end
end

total_count = policies.size

count = 0

policies.each do |policy|
  puts "#{Time.now} - 0/#{total_count}" if count == 0
  count += 1
  puts "#{Time.now} - #{count}/#{total_count}" if count % 10000 == 0 || count == total_count
  next if policy.transaction_set_enrollments.size == 0
  policy.transaction_set_enrollments.each do |tse|
    next if tse.submitted_at < date_cutoff
    transaction_type = find_transaction_type(tse.body.read)
    unless transaction_type == "other"
      if tse.submitted_at.month == 1
        if transaction_type == "reinstate"
          jan_reinstate += 1
        elsif transaction_type == "termination"
          jan_term += 1
        elsif transaction_type == "cancel"
          jan_cancel += 1
        end
      elsif tse.submitted_at.month == 2
        if transaction_type == "reinstate"
          feb_reinstate += 1
        elsif transaction_type == "termination"
          feb_term += 1
        elsif transaction_type == "cancel"
          feb_cancel += 1
        end
      elsif tse.submitted_at.month == 3
        if transaction_type == "reinstate"
          mar_reinstate += 1
        elsif transaction_type == "termination"
          mar_term += 1
        elsif transaction_type == "cancel"
          mar_cancel += 1
        end
      elsif tse.submitted_at.month == 4
        if transaction_type == "reinstate"
          apr_reinstate += 1
        elsif transaction_type == "termination"
          apr_term += 1
        elsif transaction_type == "cancel"
          apr_cancel += 1
        end
      elsif tse.submitted_at.month == 5
        if transaction_type == "reinstate"
          may_reinstate += 1
        elsif transaction_type == "termination"
          may_term += 1
        elsif transaction_type == "cancel"
          may_cancel += 1
        end
      elsif tse.submitted_at.month == 6
        if transaction_type == "reinstate"
          jun_reinstate += 1
        elsif transaction_type == "termination"
          jun_term += 1
        elsif transaction_type == "cancel"
          jun_cancel += 1
        end
      elsif tse.submitted_at.month == 7
        if transaction_type == "reinstate"
          jul_reinstate += 1
        elsif transaction_type == "termination"
          jul_term += 1
        elsif transaction_type == "cancel"
          jul_cancel += 1
        end
      elsif tse.submitted_at.month == 8
        if transaction_type == "reinstate"
          aug_reinstate += 1
        elsif transaction_type == "termination"
          aug_term += 1
        elsif transaction_type == "cancel"
          aug_cancel += 1
        end
      elsif tse.submitted_at.month == 9
        if transaction_type == "reinstate"
          sep_reinstate += 1
        elsif transaction_type == "termination"
          sep_term += 1
        elsif transaction_type == "cancel"
          sep_cancel += 1
        end
      elsif tse.submitted_at.month == 10
        if transaction_type == "reinstate"
          oct_reinstate += 1
        elsif transaction_type == "termination"
          oct_term += 1
        elsif transaction_type == "cancel"
          oct_cancel += 1
        end
      elsif tse.submitted_at.month == 11
        if transaction_type == "reinstate"
          nov_reinstate += 1
        elsif transaction_type == "termination"
          nov_term += 1
        elsif transaction_type == "cancel"
          nov_cancel += 1
        end
      elsif tse.submitted_at.month == 12
        if transaction_type == "reinstate"
          dec_reinstate += 1
        elsif transaction_type == "termination"
          dec_term += 1
        elsif transaction_type == "cancel"
          dec_cancel += 1
        end
      end
    end
  end
end

CSV.open("monthly_cancellation_termination_reinstate_data_#{Time.now.strftime("%Y%m%d%H%M%S")}.csv","w") do |csv|
  csv << ["Month","Reinstates","Cancellations","Terminations"]
  csv << ["January",jan_reinstate,jan_cancel,jan_term]
  csv << ["February",feb_reinstate,feb_cancel,feb_term]
  csv << ["March",mar_reinstate,mar_cancel,mar_term]
  csv << ["April",apr_reinstate,apr_cancel,apr_term]
  csv << ["May",may_reinstate,may_cancel,may_term]
  csv << ["June",jun_reinstate,jun_cancel,jun_term]
  csv << ["July",jul_reinstate,jul_cancel,jul_term]
  csv << ["August",aug_reinstate,aug_cancel,aug_term]
  csv << ["September",sep_reinstate,sep_cancel,sep_term]
  csv << ["October",oct_reinstate,oct_cancel,oct_term]
  csv << ["November",nov_reinstate,nov_cancel,nov_term]
  csv << ["December",dec_reinstate,dec_cancel,dec_term]
end