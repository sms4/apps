module CommentAbility
  extend ActiveSupport::Concern

  def comment_abilities(user)
    can :read, Comment

    if user
      can :create, Comment
      unless user.is_admin?
        cannot :create, Comment do |comment|
          comment.specialized? && !user.specialist?
        end
      end

      can :manage, Comment, user_id: user.id
    end
  end
end
