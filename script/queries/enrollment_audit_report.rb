require 'pry'
require 'csv'
require 'mongoid'

puts "Started at #{Time.now}"

db = Mongoid::Sessions.default
person_collection = db[:people]

start_date_1 = Time.mktime(2015,10,15,0,0,0)
start_date_2 = Time.mktime(2015,11,1,0,0,0)
start_date_3 = Time.mktime(2015,12,1,0,0,0)
start_date_4 = Time.mktime(2016,1,1,0,0,0)
start_date_5 = Time.mktime(2016,2,1,0,0,0)
start_date_6 = Time.mktime(2016,3,1,0,0,0)
start_date_7 = Time.mktime(2016,4,1,0,0,0)
start_date_8 = Time.mktime(2016,5,1,0,0,0)
start_date_9 = Time.mktime(2016,6,1,0,0,0)
start_date_10 = Time.mktime(2016,7,1,0,0,0)

start_dates = [start_date_1,start_date_2,start_date_3,start_date_4,start_date_5,start_date_6,start_date_7,start_date_8,
               start_date_9,start_date_10]

def dependent_end_date(policy)
    if policy.enrollees.any? {|enrollee| enrollee.coverage_end != nil} == true
        return true
    else
        return false
    end
end

def date_term_sent(policy,end_date)
    formatted_end_date = end_date_formatter(end_date)
    termination_transactions = []
    policy.transaction_set_enrollments.each do |tse|
        if tse.body.read.match(formatted_end_date) != nil && (tse.body.read.match("TERM")||tse.body.read.match("CANCEL"))
            termination_transactions.push(tse)
        end
    end
    if termination_transactions.size > 0
        termination_transactions.sort_by(&:submitted_at)
        return termination_transactions.first.submitted_at
    else
        return "No File Found"
    end
end

def end_date_formatter(date)
    year = date.year.to_s
    month = date.month.to_s
    if month.length == 1
        month = "0"+month
    end
    day = date.day.to_s
    if day.length == 1
        day = "0"+day
    end
    return year+month+day
end

def select_shop_plan_year(policy,employer)
    plan_years = employer.plan_years
    return nil if plan_years.size == 0
    start_date = policy.subscriber.coverage_start
    correct_plan_year = []
    plan_years.each do |plan_year|
        py_start = plan_year.start_date
        py_end = plan_year.end_date
        date_range = (py_start..py_end)
        if date_range.include?(start_date)
            end_dates = date_range.to_a.map(&:end_of_month).uniq
            correct_plan_year.push(plan_year)
            return end_dates
        end
        if correct_plan_year.size == 0
            return nil
        end
    end
end

def select_ivl_plan_year(policy)
    if policy.subscriber.coverage_start.year == 2014
        py_start = Date.new(2014,1,1)
        py_end = Date.new(2014,12,31)
        date_range = (py_start..py_end)
        end_dates = date_range.to_a.map(&:end_of_month).uniq
        return end_dates
    elsif policy.subscriber.coverage_start.year == 2015
        py_start = Date.new(2015,1,1)
        py_end = Date.new(2015,12,31)
        date_range = (py_start..py_end)
        end_dates = date_range.to_a.map(&:end_of_month).uniq
        return end_dates
    elsif policy.subscriber.coverage_start.year == 2016
        py_start = Date.new(2016,1,1)
        py_end = Date.new(2016,12,31)
        date_range = (py_start..py_end)
        end_dates = date_range.to_a.map(&:end_of_month).uniq
        return end_dates
    end
end

def date_hash_formatter(month)
    if month == 1
        return :jan
    elsif month == 2
        return :feb
    elsif month == 3
        return :mar
    elsif month == 4
        return :apr
    elsif month == 5
        return :may
    elsif month == 6
        return :jun
    elsif month == 7
        return :jul
    elsif month == 8
        return :aug
    elsif month == 9
        return :sep
    elsif month == 10
        return :oct
    elsif month == 11
        return :nov
    elsif month == 12
        return :dec
    end
end

def monthly_premiums(policy)
    nil_hash = {:jan => "0.0",:feb => "0.0",:mar => "0.0",:apr => "0.0", 
                :may => "0.0",:jun => "0.0",:jul => "0.0",:aug => "0.0",
                :sep => "0.0",:oct => "0.0",:nov => "0.0",:dec => "0.0"}
    monthly_premiums_hash = nil_hash
    begin
    policy_disposition = PolicyDisposition.new(policy)
    if policy.is_shop?
        check_dates = select_shop_plan_year(policy,policy.employer)
        return nil_hash if check_dates == nil
        monthly_premiums = []
        check_dates.each do |date|
            monthly_premium = policy_disposition.as_of(date).pre_amt_tot.to_s rescue "0.0"
            month = date_hash_formatter(date.month)
            monthly_premiums_hash[month] = monthly_premium
        end
        return monthly_premiums_hash
    else # if policy isn't shop
        check_dates = select_ivl_plan_year(policy)
        monthly_premiums = []
        check_dates.each do |date|
            monthly_premium = policy_disposition.as_of(date).pre_amt_tot.to_s rescue "0.0"
            month = date_hash_formatter(date.month)
            monthly_premiums_hash[month] = monthly_premium
        end
        return monthly_premiums_hash
    end
    rescue Exception=>e
        puts "#{Time.now} - (count not available) #{policy._id} - #{e.inspect}"
        puts "------"
        puts e.backtrace
        puts "------"
    end
end

def monthly_aptc(policy)
    monthly_aptc_hash = {}
    policy_disposition = PolicyDisposition.new(policy)
    check_dates = select_ivl_plan_year(policy)
    check_dates.each do |date|
        monthly_aptc = policy_disposition.as_of(date).applied_aptc.to_s rescue "0.0"
        month = date_hash_formatter(date.month)
        monthly_aptc_hash[month] = monthly_aptc
    end
    return monthly_aptc_hash
end

def use_existing_contributions(policy,total_premium)
    if total_premium == nil
        return ""
    elsif total_premium == "0.0"
        return ""
    end
    prem_contribs = {}
    current_premium = policy.pre_amt_tot.to_d
    current_contribution = policy.tot_emp_res_amt.to_d
    prem_contribs[current_premium] = current_contribution
    policy.versions.each do |version|
        version_premium = version.pre_amt_tot.to_d
        version_contribution = version.tot_emp_res_amt.to_d
        prem_contribs[version_premium] = version_contribution
    end
    if prem_contribs[total_premium.to_d] == nil
        return "0.0"
    else
        return prem_contribs[total_premium.to_d] rescue "0.0"
    end
end

error_policies = []

timestamp = Time.now.strftime('%Y%m%d%H%M')

tc = 0

start_dates.each do |sd|
    if sd == Time.mktime(2016,7,1,0,0,0)
        ed = Time.mktime(2016,7,15,23,59,59)
    else
        ed = sd.end_of_month
    end
    created_enrollments = Policy.where(:created_at => {"$gte" => sd, "$lte" => ed})
    potential_terminations = Policy.where(:updated_at => {"$gte" => sd, "$lte" => ed})

    has_terminated_member = []

    potential_terminations.each do |policy|
        next if policy.subscriber == nil
        if policy.canceled?
            has_terminated_member.push(policy)
        elsif policy.terminated?
            has_terminated_member.push(policy)
        elsif dependent_end_date(policy) == true
            has_terminated_member.push(policy)
        end
    end

    all_policies_to_analyze = (created_enrollments + has_terminated_member).uniq!

    total_count = all_policies_to_analyze.size

    count = 0

    Caches::MongoidCache.with_cache_for(Carrier, Plan, Employer) do

        CSV.open("enrollment_audit_report_#{timestamp}_#{sd.in_time_zone('Eastern Time (US & Canada)').strftime('%m-%d-%Y')}-#{ed.in_time_zone('Eastern Time (US & Canada)').strftime('%m-%d-%Y')}.csv","w") do |csv|       
            csv << ["First Name","Last Name","HBX ID","DOB","Market","Policy ID","Carrier","QHP ID","Plan Name",
                    "Start Date","End Date","Date Termination Sent","Plan Metal Level","Premium Total",
                    "","","","","","","","","","","",
                    "APTC/Employer Contribution",
                    "","","","","","","","","","","",
                    "Employer Name","Employer FEIN"]
            csv << ["","","","","","","","","","","","","",
                    "January","February","March","April","May","June","July","August","September","October","November","December",
                    "January","February","March","April","May","June","July","August","September","October","November","December"]
            all_policies_to_analyze.each do |policy|
                count += 1
                if count.to_d % 1000.to_d == 0
                    puts "#{Time.now} - #{count} out of #{total_count} done for #{sd} to #{ed}."
                end

                ## Policy Level Stuff
                market = policy.market
                policy_id = policy._id
                carrier = Caches::MongoidCache.lookup(Carrier, policy.carrier_id) {policy.carrier}
                carrier_name = carrier.name
                plan = Caches::MongoidCache.lookup(Plan, policy.plan_id) {policy.plan}
                plan_hios_id = plan.hios_plan_id
                plan_name = plan.name
                plan_metal_level = plan.metal_level
                employer_name = "IVL"
                employer_fein = "N/A"
                
                if policy.subscriber == nil
                    policy.enrollees.each do |enrollee|
                        hbx_id = enrollee.m_id
                        enrollee_person = person_collection.find("members.hbx_member_id" => hbx_id).first
                        first_name = enrollee_person["name_first"]
                        last_name = enrollee_person["name_last"]
                        dob = enrollee_person["members"].first["dob"]
                        start_date = enrollee.coverage_start
                        end_date = nil
                        if enrollee.coverage_end != nil
                            end_date = enrollee.coverage_end
                            date_sent = date_term_sent(policy,end_date)
                            premium_data = "Monthly Premiums Cannot be Calculated Due to Lack of a Subscriber"
                            csv << [first_name, last_name, hbx_id, dob, market, policy_id, carrier_name, plan_hios_id, plan_name,
                                    start_date, end_date, date_sent, plan_metal_level,premium_data,""*23,employer_name,employer_fein]
                        end
                    end
                end

                if policy.subscriber != nil
                    if policy.is_shop?
                        employer = Caches::MongoidCache.lookup(Employer, policy.employer_id) {policy.employer}
                        employer_name = employer.name
                        employer_fein = employer.fein
                    else
                        monthly_aptc = monthly_aptc(policy)
                    end
                    monthly_premiums = monthly_premiums(policy)

                    if policy.is_shop?  
                        begin
                            jan = monthly_premiums[:jan]
                            feb = monthly_premiums[:feb]
                            mar = monthly_premiums[:mar]
                            apr = monthly_premiums[:apr]
                            may = monthly_premiums[:may]
                            jun = monthly_premiums[:jun]
                            jul = monthly_premiums[:jul]
                            aug = monthly_premiums[:aug]
                            sep = monthly_premiums[:sep]
                            oct = monthly_premiums[:oct]
                            nov = monthly_premiums[:nov]
                            dec = monthly_premiums[:dec]
                        rescue Exception=>e
                            puts "#{Time.now} - #{count} #{policy._id} - #{e.inspect}"
                            puts "-"*6
                            puts e.backtrace
                            puts "-"*6
                        end

                        begin
                            jan_contrib = use_existing_contributions(policy,jan)
                            feb_contrib = use_existing_contributions(policy,feb)
                            mar_contrib = use_existing_contributions(policy,mar)
                            apr_contrib = use_existing_contributions(policy,apr)
                            may_contrib = use_existing_contributions(policy,may)
                            jun_contrib = use_existing_contributions(policy,jun)
                            jul_contrib = use_existing_contributions(policy,jul)
                            aug_contrib = use_existing_contributions(policy,aug)
                            sep_contrib = use_existing_contributions(policy,sep)
                            oct_contrib = use_existing_contributions(policy,oct)
                            nov_contrib = use_existing_contributions(policy,nov)
                            dec_contrib = use_existing_contributions(policy,dec)
                        rescue Exception=>e
                            puts "#{Time.now} - #{count} #{policy._id} - #{e.inspect}"
                            puts "-"*6
                            puts e.backtrace
                            puts "-"*6
                        end
                    else    
                        begin
                            jan = monthly_premiums[:jan]
                            feb = monthly_premiums[:feb]
                            mar = monthly_premiums[:mar]
                            apr = monthly_premiums[:apr]
                            may = monthly_premiums[:may]
                            jun = monthly_premiums[:jun]
                            jul = monthly_premiums[:jul]
                            aug = monthly_premiums[:aug]
                            sep = monthly_premiums[:sep]
                            oct = monthly_premiums[:oct]
                            nov = monthly_premiums[:nov]
                            dec = monthly_premiums[:dec]
                        rescue Exception=>e
                            puts "#{Time.now} - #{count} #{policy._id} - #{e.inspect}"
                            puts "-"*6
                            puts e.backtrace
                            puts "-"*6
                        end

                        begin
                            jan_aptc = monthly_aptc[:jan]
                            feb_aptc = monthly_aptc[:feb]
                            mar_aptc = monthly_aptc[:mar]
                            apr_aptc = monthly_aptc[:apr]
                            may_aptc = monthly_aptc[:may]
                            jun_aptc = monthly_aptc[:jun]
                            jul_aptc = monthly_aptc[:jul]
                            aug_aptc = monthly_aptc[:aug]
                            sep_aptc = monthly_aptc[:sep]
                            oct_aptc = monthly_aptc[:oct]
                            nov_aptc = monthly_aptc[:nov]
                            dec_aptc = monthly_aptc[:dec]
                        rescue Exception=>e
                            puts "#{Time.now} - #{count} #{policy._id} - #{e.inspect}"
                            puts "-"*6
                            puts e.backtrace
                            puts "-"*6
                        end 
                    end
                
                ## Enrollee Level Stuff
                    policy.enrollees.each do |enrollee| 
                        hbx_id = enrollee.m_id
                        enrollee_person = person_collection.find("members.hbx_member_id" => hbx_id).first
                        first_name = enrollee_person["name_first"]
                        last_name = enrollee_person["name_last"]
                        dob = enrollee_person["members"].first["dob"]
                        start_date = enrollee.coverage_start
                        end_date = nil
                        if enrollee.coverage_end != nil
                            end_date = enrollee.coverage_end
                            date_sent = date_term_sent(policy,end_date)
                            if policy.is_shop?
                                csv << [first_name, last_name, hbx_id, dob, market, policy_id, carrier_name, plan_hios_id, plan_name,
                                        start_date, end_date, date_sent, plan_metal_level,
                                        jan,feb,mar,apr,may,jun,jul,aug,sep,oct,nov,dec,
                                        jan_contrib,feb_contrib,mar_contrib,apr_contrib,may_contrib,jun_contrib,jul_contrib,aug_contrib,sep_contrib,
                                        oct_contrib,nov_contrib,dec_contrib,
                                        employer_name,employer_fein]
                            else ## if it's not shop
                                csv << [first_name, last_name, hbx_id, dob, market, policy_id, carrier_name, plan_hios_id, plan_name,
                                        start_date, end_date, date_sent, plan_metal_level,
                                        jan,feb,mar,apr,may,jun,jul,aug,sep,oct,nov,dec,
                                        jan_aptc,feb_aptc,mar_aptc,apr_aptc,may_aptc,jun_aptc,jul_aptc,aug_aptc,sep_aptc,oct_aptc,nov_aptc,dec_aptc,
                                        employer_name,employer_fein]
                            end
                        else ## if there's no end date.
                            if policy.is_shop?
                                csv << [first_name, last_name, hbx_id, dob, market, policy_id, carrier_name, plan_hios_id, plan_name,
                                        start_date, "", "", plan_metal_level,
                                        jan,feb,mar,apr,may,jun,jul,aug,sep,oct,nov,dec,
                                        jan_contrib,feb_contrib,mar_contrib,apr_contrib,may_contrib,jun_contrib,jul_contrib,aug_contrib,sep_contrib,
                                        oct_contrib,nov_contrib,dec_contrib,
                                        employer_name,employer_fein]
                            else ## if it's not shop
                                csv << [first_name, last_name, hbx_id, dob, market, policy_id, carrier_name, plan_hios_id, plan_name,
                                        start_date, "", "", plan_metal_level,
                                        jan,feb,mar,apr,may,jun,jul,aug,sep,oct,nov,dec,
                                        jan_aptc,feb_aptc,mar_aptc,apr_aptc,may_aptc,jun_aptc,jul_aptc,aug_aptc,sep_aptc,oct_aptc,nov_aptc,dec_aptc,
                                        employer_name,employer_fein]
                            end
                        end
                    end
                end
            end
        end

    end # ends MongoidCache
end




puts "Finished at #{Time.now}"