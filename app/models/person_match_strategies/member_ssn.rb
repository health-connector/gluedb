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
            return select_authority_member(found_people.first, options)
          end
        end
      end
      [nil, nil]
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
