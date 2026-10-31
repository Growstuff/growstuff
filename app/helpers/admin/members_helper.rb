# frozen_string_literal: true

module Admin
  module MembersHelper
    def spam_score_badge(member)
      score = member.respond_to?(:spam_score) && member.spam_score.present? && member.spam_score > 0 ? member.spam_score : UserBehaviourDetectionService.score_for(member)
      service = UserBehaviourDetectionService.new(member)
      reasons = service.reasons

      badge_class = if score >= 50
                      'bg-danger'
                    elsif score >= 20
                      'bg-warning text-dark'
                    else
                      'bg-success'
                    end

      tooltip = reasons.any? ? reasons.join('; ') : 'No suspicious behavior detected'

      tag.span(score, class: "badge #{badge_class} spam-score-badge", title: tooltip, data: { toggle: 'tooltip' })
    end
  end
end
