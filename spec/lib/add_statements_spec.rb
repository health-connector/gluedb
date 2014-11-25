require 'rails_helper'

describe AddStatements do
  subject { AddStatements }

  let(:person) { Person.new(name_first: 'First', name_last: 'Last') }
  let(:financial_statements) do
    [
        {
          is_primary_applicant: true,
          tax_filing_status: 'tax_filer',
          is_tax_filing_together: true,
          is_enrolled_for_es_coverage: true,
          is_without_assistance: true,
          submission_date: Date.today,
          is_ia_eligible: true,
          is_medicaid_chip_eligible: true,
          incomes: [
            {
              amount_in_cents: 100,
              kind: 'wages_and_salaries',
              frequency: 'biweekly',
              start_date: Date.today.prev_year,
              end_date: Date.today.prev_month,
              is_projected?: false,
              submission_date: Date.today,
              evidence_flag: false,
              reported_by: 'Some Guy'
            }
          ],
          deductions: [
            {
              amount_in_cents: 100,
              kind: 'alimony_paid',
              frequency: 'biweekly',
              start_date: Date.today.prev_year,
              end_date: Date.today.prev_month,
              evidence_flag: true,
              reported_date: Date.today,
              reported_by: 'Some Guy'
            }
          ],
          alternate_benefits: [
            {
              kind: 'medicaid',
              start_date: Date.today.prev_year,
              end_date: Date.today.prev_month,
              submission_date: Date.today
            }
          ]
        }
      ]
  end

  let(:requested_submission_date) { Date.today }

  it 'adds assistance eligibilities to person' do
    subject.import!(person, financial_statements)

    expect(person.financial_statements.length).to eq 1

    statement = person.financial_statements.last

    requested_statement = financial_statements.first
    expect(statement.is_primary_applicant).to eq requested_statement[:is_primary_applicant]
    expect(statement.tax_filing_status).to eq requested_statement[:tax_filing_status]
    expect(statement.is_tax_filing_together).to eq requested_statement[:is_tax_filing_together]
    expect(statement.is_enrolled_for_es_coverage).to eq requested_statement[:is_enrolled_for_es_coverage]
    expect(statement.is_without_assistance).to eq requested_statement[:is_without_assistance]
    expect(statement.submission_date).to eq requested_statement[:submission_date]
    expect(statement.is_ia_eligible).to eq requested_statement[:is_ia_eligible]
    expect(statement.is_medicaid_chip_eligible).to eq requested_statement[:is_medicaid_chip_eligible]

    income = statement.incomes.last 
    requested_income = requested_statement[:incomes].first
    expect(income.amount_in_cents).to eq requested_income[:amount_in_cents]
    expect(income.kind).to eq requested_income[:kind]
    expect(income.frequency).to eq requested_income[:frequency]
    expect(income.start_date).to eq requested_income[:start_date]
    expect(income.end_date).to eq requested_income[:end_date]
    expect(income.is_projected?).to eq requested_income[:is_projected?]
    expect(income.submission_date).to eq requested_income[:submission_date]
    expect(income.evidence_flag).to eq requested_income[:evidence_flag]
    expect(income.reported_by).to eq requested_income[:reported_by]

    deduction = statement.deductions.last
    requested_deduction = requested_statement[:deductions].first
    expect(deduction.amount_in_cents).to eq requested_deduction[:amount_in_cents]
    expect(deduction.kind).to eq requested_deduction[:kind]
    expect(deduction.frequency).to eq requested_deduction[:frequency]
    expect(deduction.start_date).to eq requested_deduction[:start_date]
    expect(deduction.end_date).to eq requested_deduction[:end_date]
    expect(deduction.evidence_flag).to eq requested_deduction[:evidence_flag]
    expect(deduction.reported_by).to eq requested_deduction[:reported_by]

    alt_benefit = statement.alternate_benefits.last
    requested_alt_benefit = requested_statement[:alternate_benefits].first
    expect(alt_benefit.kind).to eq requested_alt_benefit[:kind]
    expect(alt_benefit.start_date).to eq requested_alt_benefit[:start_date]
    expect(alt_benefit.end_date).to eq requested_alt_benefit[:end_date]
    expect(alt_benefit.submission_date).to eq requested_alt_benefit[:submission_date]
  end

  it 'saves the person' do
    expect(person).to receive(:save!)
    subject.import!(person, financial_statements)
  end

  context 'when statement already exists with submission date' do 
    before { person.financial_statements << FinancialStatement.new(submission_date: requested_submission_date)}
    it 'does not add to person' do  
      subject.import!(person, financial_statements)
      expect(person.financial_statements.count).to eq 1
    end
  end


end
