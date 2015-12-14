module Shared
class Administration::ChangelogsController < AdministrationController
  authorize_resource class: Shared::Changelog

  def index
    @changelogs  = Shared::Changelog.all.sort
    @changelog ||= Shared::Changelog.new
  end

  def create
    @changelog = Shared::Changelog.new(changelog_params)

    if @changelog.save
      form_message :notice, t('changelog.create.success'), key: params[:tab]

      redirect_to administration_root_path(tab: params[:tab])
    else
      form_error_messages_for @changelog, flash: flash.now, key: params[:tab]

      render 'shared/administration/changelogs/index'
    end
  end

  def update
    @changelog = Shared::Changelog.find(params[:id])

    if @changelog.update_attributes(changelog_params)
      form_message :notice, t('changelog.update.success'), key: params[:tab]
    else
      form_error_messages_for @changelog, key: params[:tab]
    end

    redirect_to shared.administration_changelogs_path
  end

  def destroy
    @changelog = Shared::Changelog.find(params[:id])

    if @changelog.destroy
      form_message :notice, t('changelog.delete.success'), key: params[:tab]
    else
      form_error_message t('changelog.delete.failure'), key: params[:tab]
    end

    redirect_to shared.administration_changelogs_path
  end

  private

  def changelog_params
    params.require(:changelog).permit(:version, :title, :text)
  end
end
end
