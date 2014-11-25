class AddStatements
  def self.import!(person, aes)

    aes.each do |requested_statement|
      statement = FinancialStatement.new(requested_statement)   
      if person.financial_statements.any? { |e| e.submission_date == requested_statement[:submission_date]} 
        next
      end
      person.financial_statements << statement
    end

    bad_aes = person.financial_statements.reject(&:valid?)
    if bad_aes.any?
      statement = bad_aes.first
      bad_incomes = statement.incomes.reject(&:valid?)
      bad_deductions = statement.deductions.reject(&:valid?)
      bad_alts = statement.alternate_benefits.reject(&:valid?)
      if bad_incomes.any?
        raise aes.inspect
        raise bad_incomes.first.errors.inspect
      end
      if bad_deductions.any?
        raise bad_deductions.first.errors.inspect
      end
      if bad_alts.any?
        raise bad_alts.first.errors.inspect
      end
      raise bad_aes.first.errors.inspect
    end

    person.save!
  end
end
