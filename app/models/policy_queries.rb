class PolicyQueries
  def self.with_aptc
    {"applied_aptc" => {
      "$nin" => [nil, "0.0", "0.00", "0"]}
    }
  end
  def self.without_aptc
    { 
      "applied_aptc" => {
         "$in" => [nil, "0.0", "0.00", "0"] 
      }
    }
  end
end
