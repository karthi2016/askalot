module Concerns::Flash
  def flash_error_messages(resource)
    messages = resource.errors.full_messages

    flash[:error] = Array.wrap(flash[:error]) + messages unless messages.empty?
  end
end
