module BusinessProcesses
  class EnrollmentEventErrors
    extend ActiveModel::Naming

    attr_reader :errors
    attr_reader :process
    attr_reader :event_xml
    attr_reader :employer

    delegate :add, :to => :errors

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

    private

    def initialize_clone(other)
      @errors = other.errors.clone
    end
  end
end
