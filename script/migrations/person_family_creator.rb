#This migration script will create family for every person in gluedb who does not have a family

class PersonFamilyCreator

  @@logger = Logger.new("#{Rails.root}/log/person_family_creator_#{Time.now.to_s.gsub(' ','')}.log")

  def initialize(people_with_no_families=[])
    if people_with_no_families.blank?
      @people_with_no_families = Queries::PersonWithNoFamilies.new.execute
      @people_with_no_families = @people_with_no_families[0..19]
    else
      @people_with_no_families = people_with_no_families
    end
  end

  def create
    families = []

    @people_with_no_families.each do |person|
      family = create_for(person)
      families << family if family.is_a?(Family)
    end
    families
  end

  def create_for(person)
    begin
      family_builder = FamilyBuilder.new(nil, nil)
      family_member_hash = {
          is_primary_applicant: true,
          is_coverage_applicant: true,
          is_consent_applicant: true
      }

      family_member_hash[:person] = person

      family_builder.add_family_member(family_member_hash)
      family_builder.add_hbx_enrollments
      family_builder.add_coverage_household
      family_builder.save
      family_builder.add_irsgroups
      return family_builder.family
    rescue Exception => e
      @@logger.info "#{DateTime.now.to_s} Person.id:#{person.id} Family:#{family_builder.family.errors.inspect} error message:#{e.message}"
    end
  end
end