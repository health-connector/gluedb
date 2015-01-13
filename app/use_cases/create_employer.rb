class CreateEmployer
  def initialize(listener, factory, plan_year_factory, address_factory, email_factory, phone_factory, broker_repo)
    @listener = listener
    @factory = factory
    @plan_year_factory = plan_year_factory
    @address_factory = address_factory
    @email_factory = email_factory
    @phone_factory = phone_factory
    @broker_repo = broker_repo
  end

  def execute(request)
    @employer = @factory.make(request)
    @request = request

    unless @employer.valid?
      @listener.invalid_employer(@employer.errors.to_hash)
      @listener.fail
      return
    end

    create_contact
    create_plan_year

    @employer.save!
    @listener.success
  end

  private

  def create_plan_year
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

  def create_contact
    contact_data = @request[:contact]
    name = contact_data[:name]
    @employer.name_pfx = name[:prefix]
    @employer.name_first = name[:first]
    @employer.name_middle = name[:middle]
    @employer.name_last = name[:last]
    @employer.name_sfx = name[:suffix]
    if(contact_data[:address])
      @employer.addresses << @address_factory.make(contact_data[:address])
    end
    if(contact_data[:email])
      @employer.emails << @email_factory.make(contact_data[:email])
    end
    if(contact_data[:phone])
      @employer.phones << @phone_factory.make(contact_data[:phone])
    end
  end
end
