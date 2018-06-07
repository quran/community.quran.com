class ProofReadCommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_resource
  
  def create
    render layout: false
  end
  
  def index
  
  end
  
  protected
  def load_resource
    @resource = params[:resource].
      constantize.
      find(params[:id])
  end
end
