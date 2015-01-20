module Parsers
  module Edi
    module Etf
      class ApplicationGroupParser
        attr_reader :member_ids

        def initialize(people_loops)
          @people_loops = people_loops
        end

        def persist!
          primary_loop = subscriber_loop
          people = Person.find_for_members(@people_loops.map(&:member_id))
          loop_lookup = loops_by_id

          people_lookup = @people_loops.inject({}) do |acc, per|
             found_record = people.detect do |pm|
                pm.members.any? { |m| m.hbx_member_id == per.member_id }
             end
             acc[per.member_id] = found_record
             acc
          end

          existing_application_groups = find_existing_application_groups(people.map(&:_id))
          final_group = nil
          if existing_application_groups.count > 1
            # Hooray! Merge tiems!
            final_group = merge_multiple_existing(existing_application_groups, primary_loop.member_id, loop_lookup, people_lookup)
          elsif existing_application_groups.count == 1
            # Add all the people to the existing group
            final_group = merge_with_existing(existing_application_groups.first, primary_loop.member_id, loop_lookup, people_lookup)
          else
            # Do a brand new application group
            final_group = new_application_groups(primary_loop.member_id, loop_lookup, people_lookup)
          end

          people_ids = final_group.person_relationships.inject([]) do |acc, rel|
            acc + [rel.subject_person, rel.object_person]
          end.uniq

          people_ids.each do |person_id|
            final_group.people << Person.find(person_id)
          end
          
          household = household_for_group(final_group)
          people = (final_group.people + household.people).uniq
          household.people.concat(people)

          policies = []
          final_group.people.each { |p| policies.concat(p.policies) }
          household.policies.concat(policies)

          final_group.households << household
          final_group.households.uniq!
          final_group.save!
        end

        def household_for_group(group)
          if(group.households.empty?)
            household = Household.new
          else
            household = group.households.first
          end
        end

        def subscriber_loop
          @people_loops.detect { |pl| pl.subscriber? }
        end

        def loops_by_id
          loop_lookup = @people_loops.inject({}) do |acc, pl|
            acc[pl.member_id] = pl
            acc
          end
        end

        def merge_multiple_existing(application_groups, primary_member_key, loop_lookup, people_lookup)
          prime, *rest = application_groups
          existing = extract_triples(prime)
          new_relationships = create_relationship_triples(primary_member_key, loop_lookup, people_lookup)
          other_relationships = rest.inject([]) do |acc, eag|
            acc + extract_triples(eag)
          end
          added_relationships = (new_relationships | other_relationships) - existing
          added_relationships.each do |rt|
              prime.person_relationships << PersonRelationship.new({
                :subject_person => rt[0],
                :relationship_kind => rt[1],
                :object_person => rt[2]
              })
          end
          rest.each(&:destroy!)
          prime
        end

        def create_relationship_triples(primary_member_key, loop_lookup, people_lookup)
          loop_lookup.keys.inject([]) do |acc, k|
              acc << [
                people_lookup[primary_member_key]._id.to_s,
                loop_lookup[k].group_relationship,
                people_lookup[k]._id.to_s
              ]
              acc
          end
        end

        def extract_triples(existing_group)
          existing_group.person_relationships.inject([]) do |acc, rel|
              acc << [
                rel.subject_person.to_s,
                rel.relationship_kind.to_s,
                rel.object_person.to_s
              ]
            acc
          end
        end

        def merge_with_existing(existing_group, primary_member_key, loop_lookup, people_lookup)
          existing_triples = extract_triples(existing_group)
          missing_triples = create_relationship_triples(primary_member_key, loop_lookup, people_lookup) - existing_triples
          missing_triples.each do |rt|
              existing_group.person_relationships << PersonRelationship.new({
                :subject_person => rt[0],
                :relationship_kind => rt[1],
                :object_person => rt[2]
              })
          end
          existing_group
        end

        def new_application_groups(primary_member_key, loop_lookup, people_lookup)
          new_group = Family.new
          create_relationship_triples(primary_member_key, loop_lookup, people_lookup).each do |rt|
              new_group.person_relationships << PersonRelationship.new({
                :subject_person => rt[0],
                :relationship_kind => rt[1],
                :object_person => rt[2]
              })
          end
          new_group
        end

        def find_existing_application_groups(person_ids)
          Family.where(
            "$or" => [
              {
                "person_relationships.subject_person" => { "$in" => person_ids }
              },
              {
                "person_relationships.object_person" => { "$in" => person_ids }
              }
            ]
          )
        end
      end
    end
  end
end
