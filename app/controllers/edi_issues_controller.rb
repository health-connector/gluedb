class EdiIssuesController < ApplicationController
  helper_method :sort_column, :sort_direction

  def index
    @edi_issues = EdiOpsTransaction.order_by(sort_column.to_sym.send(sort_direction))
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
