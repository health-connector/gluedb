module HandlePolicyNotification
  class ProcessingErrors
    extend ActiveModel::Naming

    attr_reader :errors

    def initialize
      @errors = ActiveModel::Errors.new(self)
    end

    def has_errors?
      !errors.empty?
    end

    def read_attribute_for_validation(attr)
      nil
    end

    def self.human_attribute_name(attr, options = {})
      attr
    end

    def self.lookup_ancestors
      [self]
    end
  end
end
