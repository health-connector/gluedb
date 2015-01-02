class PolicyBuilder

  attr_reader :policy

  def initialize(params)
    puts params.inspect
    @params = params
    set_policy_params(params)
    @policy = Policy.new(params)
    add_enrollees(params[:enrollees])
    add_enrollment(params[:enrollment])
  end

  def add_enrollees(enrollees_param)
    #puts "enrollees_param #{enrollees_param.inspect}"
    enrollees_param.each do |enrollee_param|
      enrollee = @policy.enrollees.build(enrollee_param)
      enrollee.valid?
      puts enrollee.errors.full_messages.inspect
    end
  end

  def add_enrollment(enrollment_params)
    #puts "enrollment_params #{enrollment_params.inspect}"
    #@policy.enrollment.build(enrollment_params)
  end

  def set_policy_params(params)
    params[:plan_id] = params[:enrollment][:plan][:id]
  end

  def set_enrollee_params(params)
    params[:relationship_status_code] = params[:enrollment][:plan][:id]
  end
end