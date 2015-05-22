# command to run this script
# rails r script/queries/import_families.rb


record_counter = 0
Dir.glob("/Users/CitadelFirm/Downloads/clean-xmls-19may"+'/*.xml').each do |file_path|
  iag = ImportFamilies.new(file_path)
  iag.run
  record_counter = record_counter + 1
  puts "#{file_path} record_counter #{record_counter}"
end

=begin
record_counter = 0
Dir.glob("/Users/CitadelFirm/Downloads/projects/hbx/xmls-individuals-feb-27/input-feb-17 copy/app_groups_jan14"+'/*.xml').each do |file_path|
  iag = ImportFamilies.new(file_path)
  iag.run
  record_counter = record_counter + 1
end
puts "jan record_counter #{record_counter}"


Dir.glob("/Users/CitadelFirm/Downloads/projects/hbx/xmls-individuals-feb-27/input-feb-17 copy/app_groups_feb14"+'/*.xml').each do |file_path|
  iag = ImportFamilies.new(file_path)
  iag.run
  record_counter = record_counter + 1
end
puts "feb record_counter #{record_counter}"

Dir.glob("/Users/CitadelFirm/Downloads/projects/hbx/xmls-individuals-feb-27/input-feb-17 copy/app_groups_mar14"+'/*.xml').each do |file_path|
  iag = ImportFamilies.new(file_path)
  iag.run
  record_counter = record_counter + 1
end
puts "mar record_counter #{record_counter}"


Dir.glob("/Users/CitadelFirm/Downloads/projects/hbx/xmls-individuals-feb-27/input-feb-17 copy/app_groups_apr14"+'/*.xml').each do |file_path|
  iag = ImportFamilies.new(file_path)
  iag.run
  record_counter = record_counter + 1
end
puts "apr record_counter #{record_counter}"

Dir.glob("/Users/CitadelFirm/Downloads/projects/hbx/xmls-individuals-feb-27/input-feb-17 copy/app_groups_may14"+'/*.xml').each do |file_path|
  iag = ImportFamilies.new(file_path)
  iag.run
  record_counter = record_counter + 1
end
puts "may record_counter #{record_counter}"

Dir.glob("/Users/CitadelFirm/Downloads/projects/hbx/xmls-individuals-feb-27/input-feb-17 copy/app_groups_jun14"+'/*.xml').each do |file_path|
  iag = ImportFamilies.new(file_path)
  iag.run
  record_counter = record_counter + 1
end
puts "jun record_counter #{record_counter}"

Dir.glob("/Users/CitadelFirm/Downloads/projects/hbx/xmls-individuals-feb-27/input-feb-17 copy/app_groups_jul14"+'/*.xml').each do |file_path|
  iag = ImportFamilies.new(file_path)
  iag.run
  record_counter = record_counter + 1
end
puts "jul record_counter #{record_counter}"

Dir.glob("/Users/CitadelFirm/Downloads/projects/hbx/xmls-individuals-feb-27/input-feb-17 copy/app_groups_aug14"+'/*.xml').each do |file_path|
  iag = ImportFamilies.new(file_path)
  iag.run
  record_counter = record_counter + 1
end
puts "aug record_counter #{record_counter}"

Dir.glob("/Users/CitadelFirm/Downloads/projects/hbx/xmls-individuals-feb-27/input-feb-17 copy/app_groups_sep14"+'/*.xml').each do |file_path|
  iag = ImportFamilies.new(file_path)
  iag.run
  record_counter = record_counter + 1
end
puts "sep record_counter #{record_counter}"


Dir.glob("/Users/CitadelFirm/Downloads/projects/hbx/xmls-individuals-feb-27/input-feb-17 copy/app_groups_oct14"+'/*.xml').each do |file_path|
  iag = ImportFamilies.new(file_path)
  iag.run
  record_counter = record_counter + 1
end
puts "oct record_counter #{record_counter}"

Dir.glob("/Users/CitadelFirm/Downloads/projects/hbx/xmls-individuals-feb-27/input-feb-17 copy/app_groups_nov14"+'/*.xml').each do |file_path|
  iag = ImportFamilies.new(file_path)
  iag.run
  record_counter = record_counter + 1
end
puts "nov record_counter #{record_counter}"

Dir.glob("/Users/CitadelFirm/Downloads/projects/hbx/xmls-individuals-feb-27/input-feb-17 copy/app_groups_dec14"+'/*.xml').each do |file_path|
  iag = ImportFamilies.new(file_path)
  iag.run
  record_counter = record_counter + 1
end

puts "dec record_counter #{record_counter}"

#iag = ImportFamilies.new("/Users/CitadelFirm/Downloads/projects/hbx/xmls/app_groups_jan14/2111772.xml")
#iag.run


=begin
path = "/Users/CitadelFirm/Downloads/projects/hbx/input-feb-17/app_groups_may14.xml"
iag = ImportFamilies.new(path)
iag.run
=end

=begin
path = "/Users/CitadelFirm/Downloads/projects/hbx/input-feb-17/2111757.xml"
iag = ImportFamilies.new(path)
iag.run

path = "/Users/CitadelFirm/Downloads/projects/hbx/input-feb-17/app_groups_jan14.xml"
iag = ImportFamilies.new(path)
iag.run

path = "/Users/CitadelFirm/Downloads/projects/hbx/input-feb-17/app_groups_feb14.xml"
iag = ImportFamilies.new(path)
iag.run

path = "/Users/CitadelFirm/Downloads/projects/hbx/input-feb-17/app_groups_mar14.xml"
iag = ImportFamilies.new(path)
iag.run

path = "/Users/CitadelFirm/Downloads/projects/hbx/input-feb-17/app_groups_apr14.xml"
iag = ImportFamilies.new(path)
iag.run

path = "/Users/CitadelFirm/Downloads/projects/hbx/input-feb-17/app_groups_may14.xml"
iag = ImportFamilies.new(path)
iag.run

path = "/Users/CitadelFirm/Downloads/projects/hbx/input-feb-17/app_groups_jun14.xml"
iag = ImportFamilies.new(path)
iag.run

path = "/Users/CitadelFirm/Downloads/projects/hbx/input-feb-17/app_groups_jul14.xml"
iag = ImportFamilies.new(path)
iag.run

path = "/Users/CitadelFirm/Downloads/projects/hbx/input-feb-17/app_groups_aug14.xml"
iag = ImportFamilies.new(path)
iag.run

path = "/Users/CitadelFirm/Downloads/projects/hbx/input-feb-17/app_groups_sep14.xml"
iag = ImportFamilies.new(path)
iag.run

path = "/Users/CitadelFirm/Downloads/projects/hbx/input-feb-17/app_groups_oct14.xml"
iag = ImportFamilies.new(path)
iag.run

path = "/Users/CitadelFirm/Downloads/projects/hbx/input-feb-17/app_groups_nov14.xml"
iag = ImportFamilies.new(path)
iag.run

path = "/Users/CitadelFirm/Downloads/projects/hbx/input-feb-17/app_groups_dec14.xml"
iag = ImportFamilies.new(path)
iag.run
=end