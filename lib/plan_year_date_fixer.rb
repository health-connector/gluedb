class PlanYearDateFixer

  def initialize(plan_year)
    @plan_year = plan_year
  end

  # will set end_date to 31st Dec of year. Year is taken from start_date.
  def fix_end_date
    @plan_year if @plan_year.start_date.nil?

    if @plan_year.end_date.nil?
      year = @plan_year.start_date.year
      @plan_year.end_date = Date.new(year, 12, 31)
    end
    @plan_year
  end
end

#plan_year = PlanYear.first
#puts PlanYearDateFixer.new(plan_year).fix_end_date.inspect