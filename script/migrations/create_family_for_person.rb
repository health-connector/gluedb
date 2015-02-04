#This migration script will create family for every person who does not have a family
people_with_no_families = Queries::PersonWithNoFamilies.new.execute
people_with_no_families = people_with_no_families[0..2]

people_with_no_families.each do |person|

  begin
    family_builder = FamilyBuilder.new(nil, nil)
    family_member_hash = {
        is_primary_applicant: true,
        is_coverage_applicant: true,
        is_consent_applicant: true
    }

    family_member_hash[:person] = person

    family_builder.add_family_member(family_member_hash)
    family_builder.add_hbx_enrollment
    family_builder.add_coverage_household
    family_builder.save
    family_builder.add_irsgroups
  rescue Exception=>e
    puts e.message
  end
end
