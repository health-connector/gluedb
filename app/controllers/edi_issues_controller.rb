class EdiIssuesController < ApplicationController
  before_filter :select_issue, only: [:edit, :update]

  def index
    @edi_issues = EdiOpsTransaction.all.by_oldest
  end

  def show
    @edi_issue = EdiOpsTransaction.find(params[:id])
  end

  def update
    @task.update_attributes(task_params)
  end

  private
    def set_tasks
      @edi_issue = EdiOpsTransaction.find(params[:id])
    end
end
