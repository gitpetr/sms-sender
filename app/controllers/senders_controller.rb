class SendersController < ApplicationController
  
  def index
  end

  def create
    require "smsc_api"
    sms = SMSC.new(params[:login], params[:password])
    ret = sms.send_sms(params[:phone], params[:message], 1)
    redirect_to senders_path
  end

end
