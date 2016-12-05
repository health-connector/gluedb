module BusinessProcesses
  class TransformationError < StandardError
    attr_reader :input

    def initialize(source, message)
      super(message)
      @input = source
    end
  end
end
