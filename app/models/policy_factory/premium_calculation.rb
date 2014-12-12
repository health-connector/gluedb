module PolicyFactory
  class PremiumCalculation

    def initialize(premium_calc = Premiums::PolicyCalculator.new, policy_maker = Policy)
      @policy_factory = policy_maker
      @premium_calculator = premium_calc
    end

    def create!(params)
      policy = @policy_factory.new(params)
      @premium_calculator.apply_calculations(policy)
      policy.save!
    end
  end
end
