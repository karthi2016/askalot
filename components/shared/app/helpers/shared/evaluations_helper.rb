module Shared::EvaluationsHelper
  Infinity = 1.0 / 0.0
  Boundary = 2.0 / 3.0

  def evaluation_badge_tag(evaluable, options = {})
    data  = evaluation_data evaluable
    title = evaluation_title evaluable, data[:rank]

    content_tag :span, tooltip_attributes(title, options.merge(class: :'evaluated fa-stack').reverse_merge(placement: :right)) do
      icon_tag(:circle, class: [:'fa-stack-2x', data[:color]]) + icon_tag(data[:icon], class: [:'fa-stack-1x', :'text-inverse'])
    end
  end

  def evaluation_icon_tag(evaluable, options = {})
    data  = evaluation_data evaluable
    title = evaluation_title evaluable, data[:rank]

    tooltip_icon_tag data[:icon], title, options.merge(class: data[:color]).reverse_merge(placement: :right)
  end

  def link_to_evaluation(evaluation, options = {})
    link_to_resource evaluation, options.merge(anchor: "evaluation-#{evaluation.id}")
  end

  private

  def evaluation_data(evaluable)
    case evaluable.evaluations.average(:value).to_f
    when -Infinity...-Boundary then { color: :'evaluated-bad',     icon: :'thumbs-o-down', rank: :bad }
    when -Boundary...+Boundary then { color: :'evaluated-neutral', icon: :'hand-o-right',  rank: :neutral }
    when +Boundary.. +Infinity then { color: :'evaluated-good',    icon: :'thumbs-o-up',   rank: :good }
    else fail
    end
  end

  def evaluation_title(evaluable, rank)
    translate "evaluation.rank.#{evaluable.class.name.demodulize.downcase}.#{rank}"
  end
end
