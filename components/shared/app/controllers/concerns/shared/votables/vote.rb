module Shared::Votables::Vote
  extend ActiveSupport::Concern

  def voteup
    vote true
  end

  def votedown
    vote false
  end

  private

  def vote(positive)
    @model   = controller_name.classify.downcase.to_sym
    @votable = controller_path.classify.constantize.find(params[:id])

    authorize! :vote, @votable

    @vote = @votable.toggle_vote_by!(current_user, positive)

    @votable.votes.reload

    dispatch_event dispatch_event_action_for(@vote), @vote, for: @votable.to_question.watchers

    render 'shared/votables/vote', formats: :js
  end
end
