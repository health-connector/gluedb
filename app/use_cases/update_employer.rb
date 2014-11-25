class UpdateEmployer
  def initialize(repository, address_factory, phone_factory, email_factory, plan_year_factory)
    @repository = repository
    @address_factory = address_factory
    @phone_factory = phone_factory
    @email_factory = email_factory
    @plan_year_factory = plan_year_factory
  end

  def execute(request)
    @employer = @repository.find_for_fein(request[:fein])
    @request = request
    @requested_contact = request[:contact]

    @employer.name = request[:name] unless (request[:name].nil? || request[:name].empty?)
    @employer.hbx_id = request[:hbx_id] unless (request[:hbx_id].nil? || request[:hbx_id].empty?)

    @employer.fein = request[:fein] unless (request[:fein].nil? || request[:fein].empty?)
    @employer.sic_code = request[:sic_code] unless (request[:sic_code].nil? || request[:sic_code].empty?)
    @employer.notes = request[:notes] unless (request[:notes].nil? || request[:notes].empty?)

    update_address
    update_phone
    update_email
    update_plan_year

    @employer.save!
  end

  private

  def update_address
    return unless @requested_contact[:address]

    address = @address_factory.make(@requested_contact[:address])
    @employer.merge_address(address)
  end

  def update_phone
    return unless @requested_contact[:phone]
    phone = @phone_factory.make(@requested_contact[:phone])
    @employer.merge_phone(phone)
  end

  def update_email
    return unless @requested_contact[:email]
    email = @email_factory.make(@requested_contact[:email])
    @employer.merge_email(email)
  end

  def update_plan_year
    plan_year = @plan_year_factory.make({
      open_enrollment_start: @request[:open_enrollment_start],
      open_enrollment_end: @request[:open_enrollment_end],
      start_date: @request[:plan_year_start],
      end_date: @request[:plan_year_end],
      plans: @request[:plans],
      broker_npn: @request[:broker_npn],
      fte_count: @request[:fte_count],
      pte_count: @request[:pte_count]})
    @employer.merge_plan_year(plan_year)
  end
end
