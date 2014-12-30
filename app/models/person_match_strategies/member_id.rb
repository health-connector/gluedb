module PersonMatchStrategies
  class MemberId
    def match(options = {})
      if (!options[:hbx_member_id].blank?)
        people = Person.find_for_members([options[:hbx_member_id]])
        raise AmbiguousMatchError.new("Multiple people with same member id: #{options[:hbx_member_id]}") if people.length > 1
        return([nil,nil]) if people.empty?
        person = people.first
        if !person.authority_member.present?
          raise AmbiguousMatchError.new("No authority member for member #{options[:hbx_member_id]}, person #{person.id}")
        end
        return [person, person.authority_member]
      end
      [nil, nil]
    end
  end
end
