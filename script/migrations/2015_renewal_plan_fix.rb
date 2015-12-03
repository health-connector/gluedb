FILE_PATH="/Users/CitadelFirm/Downloads/projects/hbx/enroll/plan_hios_export.csv"

CSV.foreach(FILE_PATH) do |row|
  begin
    plan_2015 = Plan.where(year: '2015').and(hios_plan_id: row[0]).first
    if plan_2015.nil?
      raise "2015 PLAN NOT FOUND" + row[0]
    end

    plan_2016 = Plan.where(year: '2016').and(hios_plan_id: row[1]).first
    if plan_2016.nil?
      raise "2016 PLAN NOT FOUND" + row[1]
    end
    plan_2015.renewal_plan = plan_2016
    plan_2015.save
    puts "#{plan_2015.name} #{row[0]} updated"

  rescue Exception => e
    puts "ERROR " + e.message
  end

end