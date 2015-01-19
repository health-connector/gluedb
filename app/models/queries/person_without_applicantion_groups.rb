module Queries
  class PersonWithoutApplicationGroups
    def initialize
    end

    def execute
      people_in_application_groups = ApplicationGroup.all.flat_map(&:applicants).flat_map(&:person).compact.uniq
      all_people = Person.all
      all_people - people_in_application_groups
    end
  end
end
