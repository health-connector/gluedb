class AddIncomeRequest
  def self.from_xml(doc)
    request_model = {}

    app_group = Family.new(doc.at_xpath('/n1:application_group/', namespaces))
    app_group.family_members.each do |applicant|
      request_model[:person_id] = applicant.person.id
      request_model[:incomes] = []
      
      applicant.incomes.each do |income_parser|
        request_model[:incomes] << {
          amount:         income_parser.dollar_amount,
          income_type:    income_parser.income_type,
          frequency:      income_parser.frequency,
          start_date:     income_parser.start_date,
          end_date:       income_parser.end_date,
          evidence_flag:  income_parser.evidence_flag,
          reported_date:  income_parser.reported_date,
          reported_by:    income_parser.reported_by
        }
      end
    end

    request_model[:current_user] = current_user    
    request_model
  end
end
