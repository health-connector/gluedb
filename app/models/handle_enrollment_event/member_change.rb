module HandleEnrollmentEvent
  class MemberChange
    include Virtus.model
    
    attribute :member_id, String

    def found_person
      @found_person ||= Person.find_by_member_id(member_id)
    end
  end
end
