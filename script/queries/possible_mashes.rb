require 'csv'

CSV.open("possible_mashes.csv", 'w') do |csv|
  csv << ["guid","hbx_id","updated","first","last","ssn","dob","gender"]

  filter_persons_by_version = Person.all.to_a.select{|per| per.version > 1}
  filter_persons_by_version.each do |person|
    if person.versions.size > 0
      if (person.versions.map(&:name_first).map(&:downcase).uniq != person.to_a.first.name_first.downcase.to_a &&
          person.versions.map(&:name_last).map(&:downcase).uniq != person.to_a.first.name_last.downcase.to_a)
          csv << [person.id,person.authority_member.hbx_member_id,person.updated_at,person.name_first,person.name_last,person.members.first.ssn,person.members.first.dob,person.members.first.gender]
          person.versions.reverse.each do |p|
            csv << ["",person.authority_member.hbx_member_id,p.updated_at,p.name_first,p.name_last,p.members.first.ssn,p.members.first.dob,p.members.first.gender]
          end
      end
    end
  end
end
