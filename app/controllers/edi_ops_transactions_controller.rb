class EdiOpsTransactionsController < ApplicationController
  helper_method :sort_column, :sort_direction, :edi_ops_transaction_path

  def index
    @q = params[:q]
    @qf = params[:qf]
    @qd = params[:qd]
    @edi_ops_transactions = EdiOpsTransaction.order_by(sort_column.to_sym.send(sort_direction)).search(@q, @qf, @qd).page(params[:page]).per(20)
  end

  def edit
    @edi_ops_transaction = EdiOpsTransaction.find(params[:id])
  end

  def update
    @edi_ops_transaction =  EdiOpsTransaction.find(params[:id])

    if @edi_ops_transaction.update_attributes(params[:edi_ops_transaction])
      redirect_to edi_ops_transactions_path
    else
      render "edit"
    end
  end

  private
    def sort_direction
      %w[asc desc].include?(params[:direction]) ?  params[:direction] : "asc"
    end

    def sort_column
      EdiOpsTransaction.fields.include?(params[:sort]) ? params[:sort] : "submitted_timestamp"
    end
end
