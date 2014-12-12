require 'rails_helper'

describe PremiumPayment do
	subject { PremiumPayment.create!(
			payment_amount_in_cents: 427.13 * 100,
			paid_at: "20140310",
			hbx_payment_type: "INTPREM",
			coverage_period: "20140401-20140430",
			policy_id: "5",
      carrier_id: "3",
			employer_id: "010569723"
		)
  }
	let(:pp) { subject }

  describe "properly instantiates object." do
		it "sets and gets all basic model fields" do
			expect(pp.payment_amount_in_cents).to eql(42713)
			expect(pp.paid_at).to eql("20140310".to_date)
			expect(pp.hbx_payment_type).to eql("INTPREM")
			expect(pp.employer_id).to eql("010569723")
		end

		it "generates start and end date from range" do
			expect(pp.coverage_start_date).to eql("20140401".to_date)
			expect(pp.coverage_end_date).to eql("20140430".to_date)
		end
	end

	describe "instance methods" do
		it "payment_in_dollars should return premium amount in currency format" do
			expect(pp.payment_amount_in_dollars).to eql(427.13)
		end
	end

end
