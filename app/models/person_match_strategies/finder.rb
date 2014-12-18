module PersonMatchStrategies
  class Finder
    def self.find_person_and_member(options = {})
      strategies = [
        MemberId.new,
        MemberSsn.new,
        FirstLastDob.new,
        FirstLastEmail.new
      ]
      person = nil
      member = nil
      strategies.each do |strat|
        s_person, s_member = strat.match(options)
        if !s_person.blank?
          person = s_person
          member = s_member
          break
        end
      end
      [person, member]
    end
  end
end
