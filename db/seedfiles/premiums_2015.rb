require 'roo'
require 'spreadsheet'

puts "Loading: 2015 Premiums"
YEAR = 2015
dates_by_sheet = [
  Date.new(YEAR, 1, 1)..Date.new(YEAR, 12, 31),
  Date.new(YEAR, 1, 1)..Date.new(YEAR, 3, 31),
  Date.new(YEAR, 4, 1)..Date.new(YEAR, 6, 30),
  Date.new(YEAR, 7, 1)..Date.new(YEAR, 9, 30),
  Date.new(YEAR, 10, 1)..Date.new(YEAR, 12, 31)
]

def import_spreadsheet(file_path, dates_by_sheet)
  spreadsheet = Roo::Spreadsheet.open(file_path)
  number_sheets = spreadsheet.sheets.count

  (0...number_sheets).each do |sheet_index|
    current_sheet = spreadsheet.sheet(sheet_index)

    header = current_sheet.row(1)
    (2..current_sheet.last_row).each do |i|
      plan_details = Hash[[header, current_sheet.row(i)].transpose]
      premiums_to_add = []

      (0..20).each do |age|
        cost = plan_details['0-20']
        premium = PremiumTable.new
        premium.rate_start_date = dates_by_sheet[sheet_index].first
        premium.rate_end_date = dates_by_sheet[sheet_index].last
        premium.age = age
        premium.amount = cost

        premiums_to_add << premium
      end

      (21..63).each do |age|
        cost = plan_details[age.to_f]
        premium = PremiumTable.new
        premium.rate_start_date = dates_by_sheet[sheet_index].first
        premium.rate_end_date = dates_by_sheet[sheet_index].last
        premium.age = age
        premium.amount = cost

        premiums_to_add << premium
      end

      (64..120).each do |age|
        cost = plan_details["64 +"]
        premium = PremiumTable.new
        premium.rate_start_date = dates_by_sheet[sheet_index].first
        premium.rate_end_date = dates_by_sheet[sheet_index].last
        premium.age = age
        premium.amount = cost

        premiums_to_add << premium
      end

      hios_id = plan_details['Standard Component ID'].gsub(/[[:space:]]/,'')
      plans = Plan.where({:hios_plan_id => /#{hios_id}/, :year => YEAR})
      puts "WARNING: No Plan found for hios: #{hios_id} from #{YEAR}" if plans.length == 0
      plans.to_a.each do |plan|
        plan.premium_tables.concat(premiums_to_add)
        plan.save!
      end
    end
  end
end

files = [
  "./db/seedfiles/premium_tables/MASTER_2015_QHP_QDP_IVL_and_SHOP_Plan_and_Rate_Matrix_v_6.xls"
]

files.each { |f| import_spreadsheet(f, dates_by_sheet) }
