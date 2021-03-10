class Api::FeedbacksController < ApplicationController
  def create
    Feedback.create feedback_params
  end

  private

  def feedback_params
    params.require(:feedback).permit(:title, :message, :email, :url, :image)
  end
end
