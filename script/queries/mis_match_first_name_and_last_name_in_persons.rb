result = []
filter_persons_by_version = Person.all.to_a.select{|per| per.version > 1} # Select rows with versioin > 1
# iterate thru each person and check if the current person's first name and last name matches with the
#previous versions of first_name and last name
filter_persons_by_version.each do |person|
  if person.versions.size > 0
    if (person.versions.map(&:name_first).map(&:downcase).uniq != person.to_a.first.name_first.downcase.to_a &&
        person.versions.map(&:name_last).map(&:downcase).uniq != person.to_a.first.name_last.downcase.to_a)
      result << person
    end
  end
end
result