module PersonMatchStrategies
  class MemberSsn
    def match(options = {})
      if !options[:ssn].blank?
        found_people = Person.where({"members.ssn" => options[:ssn]})
        if found_people.any?
          if found_people.many?
            filters = [
              [:name_last, false],
              [:name_first, true]
            ]
            person = run_filters(found_people, options, filters)
            return select_authority_member(person.first, options)
          else
            validate_no_ssn_mismatch(options, found_people.first)
            return select_authority_member(found_people.first, options)
          end
        end
      end
      [nil, nil]
    end

    def validate_no_ssn_mismatch(options, person)
      l_name_down = Maybe.new(person.name_last).downcase.value
      f_name_down = Maybe.new(person.name_first).downcase.value
      l_name_match = Maybe.new(options[:name_last]).downcase.value
      f_name_match = Maybe.new(options[:name_first]).downcase.value
      if (l_name_down != l_name_match) || (f_name_down != f_name_match)
        raise AmbiguousMatchError.new("SSN/Name mismatch #{options[:ssn]}, #{f_name_match}, #{l_name_match}; person has #{f_name_down}, #{l_name_down}")
      end
    end

    def select_authority_member(person, options)
      if !person.authority_member.present?
        raise AmbiguousMatchError.new("No authority member for ssn #{options[:ssn]}, person #{person.id}")
      end
      return [person, person.authority_member]
    end

    def run_filters(people, props, filters)
      person = catch :person_found do
        filters.inject(people) do |acc, filter|
          filter_people_by(acc, props, filter.first, filter.last)
        end
      end
      person
    end

    def filter_people_by(plist, props, sym, error_on_many = false)
      val = props[sym.to_sym]
      if !val.blank?
        filtered = plist.select { |per| per.send(sym.to_sym).downcase == val.downcase }
        if filtered.empty?
          raise AmbiguousMatchError.new("Multiple people with same ssn: #{props[:ssn]}")
        elsif filtered.length == 1
          throw(:person_found, filtered)
        else
          if error_on_many
            raise AmbiguousMatchError.new("Multiple people with same ssn: #{props[:ssn]}")
          else
            filtered
          end
        end
      end
      if plist.many? && error_on_many
        raise AmbiguousMatchError.new("Multiple people with same ssn: #{props[:ssn]}")
      end
      plist
    end
  end
end
