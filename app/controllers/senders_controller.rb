class SendersController < ApplicationController
  
  def index
  end

  def create
      require "smsc_api"
      sms = SMSC.new()
      ret = sms.send_sms(params["phone"], params["message"], 1)
      flash.now[:success] =  "Сообщение отправлено"
      redirect_to senders_path
  end

end
