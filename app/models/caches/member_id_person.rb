module Caches
  class MemberIdPerson

    def initialize(member_ids = [])
      @people = Person.find_for_members(member_ids).unscoped
      @people = @people.inject({}) do |acc, per|
        per.members.each do |m|
          acc[m.hbx_member_id] = per
        end
        acc
      end
    end

    def lookup(m_id)
      @people[m_id]
    end
  end
end
