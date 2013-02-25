class UsersController < ApplicationController
  def show
    @showing_user = User.find_by_username!(params[:id])
    @title = "User #{@showing_user.username}"
  end

  def tree
    @title = "Users"

    parents = {}
    karmas = {}
    User.all.each do |u|
      (parents[u.invited_by_user_id.to_i] ||= []).push u
    end

    Keystore.find(:all, :conditions => "`key` like 'user:%:karma'").each do |k|
      karmas[k.key[/\d+/].to_i] = k.value
    end

    @tree = []
    recursor = lambda{|user,level|
      if user
        @tree.push({ :level => level, :user_id => user.id,
          :username => user.username, :karma => karmas[user.id].to_i,
          :is_moderator => user.is_moderator?, :is_admin => user.is_admin? })
      end

      # for each user that was invited by this one, recurse with it
      (parents[user ? user.id : 0] || []).each do |child|
        recursor.call(child, level + 1)
      end
    }
    recursor.call(nil, 0)

    @tree
  end

  def invite
    @title = "Pass Along an Invitation"
  end
end
