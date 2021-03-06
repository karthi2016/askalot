module Shared
class Administration::EmailsController < AdministrationController

  def index
    authorize! :create, Shared::Email

    @email ||= Shared::Email.new
  end

  def create
    authorize! :create, Shared::Email

    if params[:test]
      Shared::Mailers::CommunityMailerService.deliver_test_email!(email_params)
      form_message :notice, t('email.create_test.success'), key: 'emails'
    else
      @email = Shared::Email.new(email_params)

      if @email.save
        form_message :notice, t('email.create.success'), key: 'emails'
      else
        form_message :error, t('email.create.failure'), key: 'emails'
      end
    end

    redirect_to shared.administration_emails_path
  end

  private

  def email_params
    email = params.require(:email).permit(:subject, :body, :send_html_email).deep_merge({ user: current_user, status: false })
    email.deep_merge({ send_html_email: email[:send_html_email] == "1" })
  end
end
end
