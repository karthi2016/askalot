module Mooc::Application
  extend ActiveSupport::Concern

  included do
    layout 'mooc/application'
    prepend_view_path 'components/mooc/app/views'

    before_action :login_required, :redirect_if_params

    private

    def login_required
      unless user_signed_in?
        @url = params[:login_url]

        render '/mooc/page/to_login_redirect' if params[:login_url]
        render '/mooc/page/no_login_url' unless params[:login_url]
      end
    end

    def redirect_if_params
      redirect_to params[:redirect] if params[:redirect]
    end
  end
end