require 'csv'
class CsvRequest
  def self.create_many(spreadsheet, current_user)
    requests = Array.new

    CSV.parse(spreadsheet, headers: true, header_converters: :symbol, skip_blanks: true).each do |row|
      requests << CsvRequest.new(row, current_user)
    end
    requests
  end

  def initialize(csv_row, current_user)
    @row = csv_row
    @current_user = current_user
  end

  def to_hash
    hash = @row.to_hash.symbolize_keys
    clean_hash = {current_user: @current_user}
    hash.each_pair do |k, v|
      clean_value = hash[k].to_s.gsub(/[\u0080-\u00ff]+/u, "").strip #NO CONTROL CHARACTERS FOR YOU
      clean_hash[k] = clean_value
    end
    clean_hash
  end

  def to_a
    @row.fields
  end
end
