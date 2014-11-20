class CommentsController < ActionController::Base
  layout "application"

  def create
    @commentable = params[:comment][:commentable].constantize.find(params[:comment][:commentable_id])
    @comment = @commentable.comments.build
    @comment.content = params[:comment][:content]
    @comment.priority = params[:comment][:priority]
    @comment.user = current_user.email
    @comment.save
    respond_to do |format|
       format.js
    end  
    ##redirect_to @commentable
  end

  def destroy
    @commentable = params[:commentable].constantize.find(params[:commentable_id])
    @comment = @commentable.comments.find(params[:id])
    @comment.destroy
    redirect_to @commentable
  end

  def show
    @commentable = params[:commentable].constantize.find(params[:commentable_id])
    @comment = @commentable.comments.find(params[:id])
  end

  def update

    @commentable = params[:comment][:commentable].constantize.find(params[:comment][:commentable_id])
    @comment = @commentable.comments.find(params[:id])

    respond_to do |format|
      if @comment.update_attributes(params[:comment])
        format.html { redirect_to @commentable, notice: 'Comment was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @commentable.errors, status: :unprocessable_entity }
      end
    end
  end
end
