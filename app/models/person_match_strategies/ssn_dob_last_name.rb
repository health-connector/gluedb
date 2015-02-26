module PersonMatchStrategies
  class SsnDobLastName < FirstLastDob

    def match(options = {})
      return([nil, nil]) if options[:dob].blank? || options[:name_last].blank? || options[:ssn].blank?

      search_dob = cast_dob(options[:dob], options)

      found_people = Person.where("members.dob" => search_dob).and("members.ssn" => options[:ssn]).to_a.select do |person|
        person.name_last.strip.downcase.eql? options[:name_last].strip.downcase
      end

      return [nil, nil] unless found_people

      if found_people.any?
        if found_people.many?
          raise AmbiguousMatchError.new("Multiple people with same ssn, last, and dob: #{options[:ssn]}, #{options[:name_last]}, #{options[:dob]}")
        else
          select_authority_member(found_people.first, options)
        end
      else
        [nil, nil]
      end
    end
  end
end