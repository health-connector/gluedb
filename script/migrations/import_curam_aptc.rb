file = "/Users/CitadelFirm/Downloads/enrollment_data_102815.csv"

def person_match(first_name, ssn, dob)
  dob = Date.strptime(dob, "%m/%d/%Y")
  people = Person.unscoped.where({"members.ssn" => @ssn}).and({"members.dob" => dob}).and({"name_first" => first_name})
  puts "multiple matches" if people.length > 1
  return people
end

CSV.foreach(File.path(file), :headers=>true) do |row|
  persons = person_match(row[0], row[3], row[2])
  if persons
    person = persons.first
    puts "FOUND #{row[0]} #{row[1]} #{row[2]} #{row[3]}"
  else
    puts "NOT FOUND #{row[0]} #{row[1]} #{row[3]} #{row[2]}"
  end
end