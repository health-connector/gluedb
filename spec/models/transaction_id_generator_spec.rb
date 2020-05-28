require "rails_helper"

describe TransactionIdGenerator do
  describe "asked to generate 2 BGN02 compatible ids" do
    it "generates them in the correct order" do
      allow(Time).to receive(:now).and_return(
        Time.mktime(2017, 5, 10, 0, 0, 0, 789),
        Time.mktime(2017, 5, 10, 0, 0, 0, 123456)
      )
      transaction_id_1 = TransactionIdGenerator.generate_bgn02_compatible_transaction_id
      transaction_id_2 = TransactionIdGenerator.generate_bgn02_compatible_transaction_id
      expect(transaction_id_1 < transaction_id_2).to be_truthy
    end
  end
end