# frozen_string_literal: true

class BlocksController < ApplicationController
  load_and_authorize_resource
  skip_load_resource only: :create

  def create
    @block = current_member.blocks.build(blocked: Member.find(params[:blocked]))

    if @block.save
      flash[:notice] = "Blocked #{@block.blocked.login_name}"
    else
      flash[:error] = "Already blocking or error while blocking."
    end
    redirect_back_or_to(root_path)
  end

  def destroy
    @block = current_member.blocks.find(params[:id])
    @unblocked = @block.blocked
    @block.destroy

    flash[:notice] = "Unblocked #{@unblocked.login_name}"
    redirect_to @unblocked
  end

  private

  def block_params
    params.permit(:id, :blocked)
  end
end
