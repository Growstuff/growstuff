# frozen_string_literal: true

class ProblemsController < ApplicationController
  before_action :authenticate_member!, except: %i(index show)
  load_and_authorize_resource id_param: :slug, class: Problem
  respond_to :html, :json

  def index
    @problems = Problem.approved.popular.paginate(page: params[:page])
    @num_requested_problems = requested_problems.size if current_member
    respond_with @problems
  end

  def requested
    @requested = requested_problems.paginate(page: params[:page])
    respond_with @requested
  end

  def show
    @problem = Problem.friendly.find(params[:id])
    @plantings = @problem.plantings.paginate(page: params[:page])
    respond_with @problem
  end

  def new
    @problem = Problem.new
    respond_with @problem
  end

  def edit; end

  def create
    @problem = Problem.new(problem_params)
    if current_member.role? :problem_wrangler
      @problem.creator = current_member
    else
      @problem.requester = current_member
      @problem.approval_status = "pending"
    end
    @problem.save
    respond_with @problem
  end

  def update
    if can?(:wrangle, @problem)
      @problem.approval_status = 'rejected' if params.fetch("reject", false)
      @problem.approval_status = 'approved' if params.fetch("approve", false)
    end
    @problem.update(problem_params)
    respond_with @problem
  end

  def wrangle
    @approval_status = params[:approval_status]
    @problems = case @approval_status
                when "pending"
                  Problem.pending_approval
                when "rejected"
                  Problem.rejected
                else
                  Problem.recent
                end.paginate(page: params[:page])
    @problem_wranglers = Role.problem_wranglers
    respond_with @problems
  end

  private

  def problem_params
    params.require(:problem).permit(:name, :reason_for_rejection, :rejection_notes)
  end

  def requested_problems
    current_member.requested_problems.pending_approval
  end
end
