require 'csv'

class MultipleAptcImporter

  attr_accessor :policies

  # file_path - path to the csv file.
  # schema - Policy ID, IssuerAPTCAmount,	IssueSubsidyStartDate,	IssuerSubsidyEndDate
  # sample row - 11912,	141,	1/1/14,	2/28/14
  def initialize(file_path)
    @file_path = file_path
    @policies = []
  end

  def match_existing_span(aptc_credit_1,aptc_credit_2)
    hash_1 = {:start_on => aptc_credit_1.start_on, :end_on => aptc_credit_1.end_on, :aptc => aptc_credit_1.aptc}
    hash_2 = {:start_on => aptc_credit_2.start_on, :end_on => aptc_credit_2.end_on, :aptc => aptc_credit_2.aptc}
    hash_1 == hash_2
  end

  def apply_multiple_aptc
    @logger = Logger.new("#{Rails.root}/log/multiple_aptc_importer_#{Time.now.to_s.gsub(' ', '')}.log")

    CSV.foreach(@file_path, :headers => :first_row) do |row|
      begin
        policy = Policy.find(row[0])
        aptc_credit = AptcCredit.new({start_on: Date.strptime(row[2], "%m/%d/%Y"),
                                   end_on: Date.strptime(row[3], "%m/%d/%Y"),
                                   aptc: row[1]})
        unless policy.aptc_credits.any?{|ac| match_existing_span(ac,aptc_credit)}
          policy.aptc_credits << aptc_credit
          aptc_credit.save!
          @policies << policy
          @logger.info "Processed Policy:#{policy.id} with APTC: " + policy.aptc_credits.inspect
        else
          @logger.info "Did not process Policy:#{policy.id} with APTC: #{aptc_credit.aptc} because of matching span."
        end
      rescue Exception => e
        @logger.error "Could not process #{row[0]} " + e.message
      end
    end
  end
end

aptc_importer = MultipleAptcImporter.new('Remine_22836_2017_MidyearAPTCChangeData.csv')
aptc_importer.apply_multiple_aptc