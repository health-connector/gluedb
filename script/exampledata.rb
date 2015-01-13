class ExampleData
  def self.load
    json_string = File.open(Rails.root.to_s + "/examples.json").read

    data = JSON.load(json_string)

    data.each do |params|
      EdiOpsTransaction.create!(params)
    end
    return false
  end
end
