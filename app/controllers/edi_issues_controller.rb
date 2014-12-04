class EdiIssuesController < ApplicationController
###helper_method :sort_column, :sort_direction  

  def index

    @q = params[:q]
      sort_col, direction = "enrollment_id", "desc"
      sort_col  = params[:sort] if params[:sort]
      direction = params[:direction] if params[:direction]
      
      
        if params[:aasm_state] == "open"
          edi_issues = EdiOpsTransaction.where(aasm_state: "open")
        else 
          if params[:aasm_state] == "close"
            edi_issues = EdiOpsTransaction.where(aasm_state: "close")
          else
            if params[:aasm_state] == "Assigned"
              edi_issues = EdiOpsTransaction.where(aasm_state: "assigned")
            else
               edi_issues = EdiOpsTransaction.all 
            end   
          end
        end
       
         
      if params[:sort] 
         if params[:direction] == "asc"
           @edi_issues = edi_issues.sort!{|e, f| e.enrollment_id <=> f.enrollment_id}
         else
           @edi_issues = edi_issues.sort!{|e, f| f.enrollment_id <=> e.enrollment_id}
         end   
      else
        @edi_issues = edi_issues
      end  

    
    
      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @edi_issues }
      end
  end  

  def show
   @edi_issue = EdiOpsTransaction.find(params[:id])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @edi_issue }
    end
  end

  
  def edit
     @edi_issue =  EdiOpsTransaction.find(params[:id])

  end  



  def update
    @edi_issue =  EdiOpsTransaction.find(params[:id])

    if @edi_issue.update_attributes(params[:edi_ops_transaction])
      redirect_to edi_issues_path
    else
      render "edit"
    end 
     
  end  




end
