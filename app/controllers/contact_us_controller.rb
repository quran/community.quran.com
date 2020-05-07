class ContactUsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :message

  def message
    headers["Access-Control-Allow-Origin"] = "*.quran.com"
    headers["Access-Control-Allow-Origin"] = "http://localhost:3000"
    contact_us = ContactMessage.new(contact_us_params)

    if contact_us.save
      render json: {message: "Thank you for contacting us. We'll get back to you soon inshAllah"}
    else
      render json: {message: 'Sorry something went wrong.'}
    end
  end

  protected

  def contact_us_params
    params
        .require(:contact)
        .permit(
            :name,
            :email,
            :subject,
            :detail
        )
  end
end