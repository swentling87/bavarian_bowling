module ResponseHandler
  extend ActiveSupport::Concern
  
  def process_response(response_bool, response_string="")
    if response_bool
      return render(json: { status: "ok", message: response_string }.to_json)
    else
      return render(json: { status: "bad", message: "There was a problem processing your request." }.to_json, status: :bad_request)
    end
  end
  
  #force presence of required parameters
  def params_check(*args)
    if !args.include?(nil)
      yield
    else
      render(json: { status: "bad", message: "There was a problem processing your request." }.to_json, status: :bad_request ) and return
    end
  end
end