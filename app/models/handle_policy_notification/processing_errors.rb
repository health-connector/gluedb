module HandlePolicyNotification
  class ProcessingErrors
    extend ActiveModel::Naming

    attr_reader :errors

    attr_reader :policy_details
    attr_reader :plan_details
    attr_reader :member_details
    attr_reader :broker_details
    attr_reader :market_type

    def initialize
      @errors = ActiveModel::Errors.new(self)
    end

    def has_errors?
      !errors.empty?
    end

    def read_attribute_for_validation(attr)
      send(attr)
    end

    def self.human_attribute_name(attr, options = {})
      attr
    end

    def self.lookup_ancestors
      [self]
    end
  end
end
