class DashboardsController < ApplicationController

  before_filter :check_access

  def index

  	@total_employers = Employer.count
  	@total_enrollments = Policy.count
  	@total_edi_transactions = Protocols::X12::TransactionSetEnrollment.count

    @transactions = {
      increments: {},
      months: {}
    }

    transactonIncrements = {
      "Last Week" => Time.now.weeks_ago( 1 ).all_week,
      "This Week" => Time.now.all_week,
      "This Month" => Time.now.all_month,
      "This Quarter" => Time.now.all_quarter,
      "This Year" => Time.now.all_year
    }

    transactonIncrements.each_pair do |humanTime, timeObj|
      numTransactions = Protocols::X12::TransactionSetEnrollment.where( submitted_at: timeObj ).count
      @transactions[ :increments ][ humanTime ] = numTransactions
    end

    @transactions[ :increments ][ "Total" ] = @total_edi_transactions

    @monthsToDisplay = 6

    (1..@monthsToDisplay).each do |monthsAgo|
      timeObj = Time.now.months_ago( @monthsToDisplay - monthsAgo + 1 )
      numTransactions = Protocols::X12::TransactionSetEnrollment.where( submitted_at: timeObj.all_month ).count
      @transactions[ :months ][ timeObj.strftime( "%B" ) ] = numTransactions
    end

    @response_metric = ResponseMetric.all
    @ambiguous_people_metric = AmbiguousPeopleMetric.all
    render :index
  end

  private

  def check_access
    redirect_to people_path and return if current_user.role == "service"
  end
end
