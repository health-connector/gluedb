class EdiIssuesController < ApplicationController
  helper_method :sort_column, :sort_direction

  def index
    @q = params[:q]
    @qf = params[:qf]
    @qd = params[:qd]
    @edi_issues = EdiOpsTransaction.order_by(sort_column.to_sym.send(sort_direction)).search(@q, @qf, @qd).page(params[:page]).per(20)
  end

  def show
    @edi_issue = EdiOpsTransaction.find(params[:id])
  end

  def update
    @task.update_attributes(task_params)
  end

  private
    def sort_direction
      %w[asc desc].include?(params[:direction]) ?  params[:direction] : "desc"
    end

    def sort_column
      EdiOpsTransaction.fields.include?(params[:sort]) ? params[:sort] : "submitted_timestamp"
  end
end
