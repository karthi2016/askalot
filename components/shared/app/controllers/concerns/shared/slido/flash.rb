module Shared::Slido::Flash
  extend ActiveSupport::Concern

  included do
    before_action :flash_slido_events
  end

  def flash_slido_events
    events = Shared::SlidoEvent.where('? between started_at and ended_at', Time.now).order(:ended_at).load

    if events.any?
      flash.now[:slido] = []

      events.each do |event|
        flash.now[:slido] << render_to_string(partial: 'shared/slido/message', locals: { event: event })
      end
    end
  end
end
