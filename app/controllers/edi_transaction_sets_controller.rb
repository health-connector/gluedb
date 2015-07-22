class EdiTransactionSetsController < ApplicationController
  def index
	  # @edi_transaction_sets = EdiTransactionSet.all
	  @edi_transaction_sets = Protocols::X12::TransactionSetEnrollment.limit(100)

    respond_to do |format|
	    format.html # index.html.erb
	    format.json { render json: @edi_transaction_sets }
	  end
  end

  def errors
    @q = params[:q]
    @transaction = Protocols::X12::TransactionSetEnrollment.search(carrier_map(@q)).where("error_list" => {"$exists" => true, "$not" => {"$size" => 0}}).page(params[:page]).per(15)
    authorize! params, @transaction || Protocols::X12::TransactionSetEnrollment
  end

  def show
		@edi_transaction_set = Protocols::X12::TransactionSetEnrollment.find(params[:id])

	  respond_to do |format|
		  format.html # index.html.erb
		  format.json { render json: @edi_transaction_set }
		end
  end

  private
    def carrier_map(name)
      c_hash = Carrier.all.to_a.inject({}){|result, c| result.merge({c.name => c.carrier_profiles.first.try(:fein)}) }
      @q = c_hash[name] if c_hash[name].present?
      @q
    end
end
