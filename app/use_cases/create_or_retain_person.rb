class CreateOrRetainPerson
  def initialize(person_params, finder = PersonMatchStrategies::Finder)
    @finder = finder
    @person_params = person_params
  end

  def match
    person = nil
    member = nil
    tries = 0

    begin
      person, member = @finder.find_person_and_member(@person_params)
    rescue PersonMatchStrategies::AmbiguousMatchError => e

      if e.message.include? 'SSN/Name mismatch'
        $logger.warn "#{DateTime.now.to_s}" +
                         "WARNING: SSN/Name mismatch\n" +
                         "message:#{e.message}\n"

        array = e.message.split('person has').last.split(',')
        first_name = array[0].strip
        last_name = array[1].strip

        matched_person, matched_member = PersonMatchStrategies::SsnDobLastName.new.match({:name_last => @person_params[:name_last],
                                                                                          :ssn => @person_params[:ssn],
                                                                                          :dob => @person_params[:dob]})
        if !matched_person.nil? && !matched_member.nil?
          #puts "#{first_name}, #{last_name}"
          @person_params[:name_first] = matched_person.name_first
          @person_params[:name_last] = matched_person.name_last
          #puts "end #{ig_request.inspect}"
          tries = tries + 1
          if tries < 2
            retry
          else
            raise(e)
          end
        else
          raise(e)
        end
      else
        raise(e)
      end
    end
  end

  def create
    person = Person.new(filter_person_params(@person_params.clone))
    member = person.members.build(filter_member_params(@person_params))
    person.authority_member_id = @person_params[:hbx_member_id]
    person.save!
    [person, member]
  end

  def filter_member_params(request)
    request.select { |k, _| member_keys.include?(k) }
  end

  def member_keys
    [:ssn, :dob, :gender, :hbx_member_id]
  end

  def filter_person_params(person_params)
    person_params = person_params.clone
    person_params.delete_if do |k, v| member_keys.include? k end
  end
end