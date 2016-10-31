module HandlePolicyNotification
  class EmployerDetails
    include Virtus.model

    attribute :fein, String

    def found_employer
      @found_employer ||= Employer.where(fein: fein).first
    end
  end
end
