class PolicyQueries
  def self.without_aptc
    {
      "$or" => [
        {"applied_aptc" => {
          "$in" => [nil, "0.0", "0.00", "0"]
        }},
        {"applied_aptc" => {
          "$exists" => false
        }}
      ]
    }
  end
end
