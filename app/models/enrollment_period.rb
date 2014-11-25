class EnrollmentPeriod
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM

  field :aasm_state

  open_enrollment_2015 = Date.parse('2014-11-15')..Date.parse('2015-02-15')
  open_enrollment_2016 = Date.parse('2015-10-15')..Date.parse('2015-12-07')
  open_enrollment_2017 = Date.parse('2016-10-15')..Date.parse('2016-12-07')

  aasm do
    state :closed_enrollment, initial: true
    state :open_enrollment_period

    event :open_enrollment do
      transitions from: [:closed_enrollment, :open_enrollment_period], to: :open_enrollment_period
    end

    event :closed_enrollment do
      transitions from: [:open_enrollment_period, :closed_enrollment], to: :closed_enrollment
    end
  end

end
