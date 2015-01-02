class PolicyBuilder

  attr_reader :policy

  def initialize(params)
    @params = params
    @policy = Policy.new(params)
  end
end