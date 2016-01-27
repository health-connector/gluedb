module Queries
  class PersonWithNoFamilies
    def initialize
    end

    def execute
      people_in_families = Family.all.flat_map(&:family_members).flat_map(&:person).compact.uniq
      all_people = Person.all
      all_people - people_in_families
    end
  end
end
