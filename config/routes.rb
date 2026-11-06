# typed: false

DOMAINS_IDENTIFIER = /([^\/]+?)(?=\.json|\.rss|$|\/)/ # match example.com but not example.com.rss
ORIGINS_IDENTIFIER = /(.+)(?=\.json|\.rss|$|\/)/ # match github.com/user but not github.com/user.rss

Rails.application.routes.draw do
  root to: "home#index",
    protocol: (Rails.application.config.force_ssl ? "https://" : "http://"),
    as: "root"

  # Rails misdesign: if a route doesn't support a format, Rails calls it anyways and then
  # raises MissingTemplate when it's not handled, as if the app did something wrong (a prod 500!).
  # Having to scope all the routes to avoid this is called convention over configuration. #746
  scope format: "html" do
    get "/404" => "about#four_oh_four", :via => :all

    get "/rss" => "home#index", :format => "rss"
    get "/hottest" => "home#index", :format => "json"

    get "/page/:page" => "home#index", :format => /html|json|rss/

    get "/active" => "home#active", :format => /html|json/
    get "/active/page/:page" => "home#active", :format => /html|json/
    get "/newest" => "home#newest", :format => /html|json|rss/
    get "/newest/page/:page" => "home#newest", :format => /html|json|rss/
    get "/recent" => "home#recent"
    get "/recent/page/:page" => "home#recent"
    get "/hidden" => "home#hidden"
    get "/hidden/page/:page" => "home#hidden"

    get "/saved" => "home#saved", :format => /html|json|rss/
    get "/saved/page/:page" => "home#saved", :format => /html|json|rss/
    get "/upvoted/stories" => "home#upvoted", :format => /html|json|rss/
    get "/upvoted/stories/page/:page" => "home#upvoted", :format => /html|json|rss/
    get "/upvoted/comments" => "comments#upvoted", :format => /html|rss/
    get "/upvoted/comments/page/:page" => "comments#upvoted", :format => /html|rss/
    get "/upvoted", to: redirect("/upvoted/stories")
    get "/upvoted/page/:page", to: redirect("/upvoted/stories/page/%{page}")

    get "/top/rss", to: redirect("/top.rss", status: 301)
    get "/top/:length/rss", to: redirect("/top/%{length}.rss", status: 301)
    get "/top(/:length(/page/:page))" => "home#top", :as => "top", :format => /html|rss/

    get "/threads" => "comments#user_threads"

    get "/replies", to: redirect("/inbox/all")
    get "/replies/page/:page", to: redirect("/inbox/all")
    get "/replies/comments", to: redirect("/inbox/all")
    get "/replies/comments/page/:page", to: redirect("/inbox/all")
    get "/replies/stories", to: redirect("/inbox/all")
    get "/replies/stories/page/:page", to: redirect("/inbox/all")
    get "/replies/unread", to: redirect("/inbox/unread")
    get "/replies/unread/page/:page", to: redirect("/inbox/unread")

    get "/login" => "login#index"
    post "/login" => "login#login"
    post "/logout" => "login#logout"
    get "/login/2fa" => "login#twofa"
    post "/login/2fa_verify" => "login#twofa_verify", :as => "twofa_login"

    get "/signup" => "signup#index"
    post "/signup" => "signup#signup"
    get "/signup/invite" => "signup#invite"

    get "/login/forgot_password" => "login#forgot_password",
      :as => "forgot_password"
    post "/login/reset_password" => "login#reset_password",
      :as => "reset_password"
    match "/login/set_new_password" => "login#set_new_password",
      :as => "set_new_password", :via => [:get, :post]

    get "/t/:tag" => "home#single_tag", :as => "tag", :constraints => {tag: /[^,.\/]+/}, :format => /html|json|rss/
    get "/t/:tag/page/:page" => "home#single_tag", :constraints => {tag: /[^,.\/]+/}, :format => /html|json|rss/
    get "/t/:tag" => "home#multi_tag", :as => "multi_tag", :format => /html|json|rss/
    get "/t/:tag/page/:page" => "home#multi_tag", :format => /html|json|rss/

    constraints id: DOMAINS_IDENTIFIER do
      get "/domain/:id(.:format)", to: redirect("/domains/%{id}"), format: /html|json|rss/
      get "/domain/:id/page/:page", to: redirect("/domains/%{id}/page/%{page}")
      get "/domains/:id(.:format)" => "home#for_domain", :as => "domain", :format => /html|json|rss/
      get "/domains/:id/page/:page" => "home#for_domain", :format => /html|json|rss/
      get "/domains/:id/origins" => "origins#for_domain", :as => "domain_origins"
      get "/domains/:id/:author", to: redirect("/origins/%{id}/%{author}")
      get "/domain/:domain/:identifier(.:format)", to: redirect("/domains/%{domain}/%{identifier}"), format: /html|json|rss/
      get "/domain/:domain/:identifier/page/:page", to: redirect("/domains/%{domain}/%{identifier}/page/%{page}")
    end

    constraints identifier: ORIGINS_IDENTIFIER do
      get "/origins/:identifier(.:format)" => "home#for_origin", :as => "origin", :format => /html|json|rss/
    end

    get "/search" => "search#index"
    get "/search/:q" => "search#index"

    get "/stories/url/all" => "story_urls#all", :format => /json/
    get "/stories/url/latest" => "story_urls#latest"

    get "/stories/new" => "stories#new", :as => "new_story"
    get "/stories/:id" => "stories#show", :as => "story", :format => /html|json/
    resources :stories, except: [:index, :new, :show] do
      get "/stories/:short_id", to: redirect("/s/%{short_id}")
      post "upvote"
      post "flag"
      post "unvote"
      patch "destroy"
      patch "undelete"
      post "hide", format: /html|json/
      post "unhide", format: /html|json/
      post "save", format: /html|json/
      post "unsave", format: /html|json/
      post "disown"
      resources :suggestions, only: [:new, :create]
    end
    post "/stories/fetch_url_attributes", format: "json"
    post "/stories/preview" => "stories#preview"
    post "/stories/check_url_dupe" => "stories#check_url_dupe", :format => /html|json/

    get "/comments/rss", to: redirect("/comments.rss")
    get "/comments" => "comments#index", :format => /html|rss/
    resources :comments, except: [:index, :new, :destroy] do
      member do
        get "/comments/:id" => "comments#redirect_from_short_id"
        get "reply"
        post "upvote"
        post "flag"
        post "unvote"

        post "delete"
        post "undelete"
        post "disown"
      end
    end
    get "/comments/page/:page" => "comments#index", :format => /html|rss/

    get "/messages/sent" => "messages#sent", :format => /html|json/
    get "/messages" => "messages#index", :format => /html|json/
    post "/messages/batch_delete" => "messages#batch_delete",
      :as => "batch_delete_messages"
    resources :messages, except: %i[new edit update] do
      post "keep_as_new"
      post "mod_note"
    end

    get "/inbox" => "inbox#index"
    get "/inbox/all(/page/:page)" => "inbox#all", :as => "inbox_all", :format => /html|json/
    get "/inbox/unread" => "inbox#unread", :format => /html|json/

    get "/c/:id.json" => "comments#show_short_id", :format => "json"
    get "/c/:id" => "comments#redirect_from_short_id", :as => "comment_short_id"

    # deprecated
    get "/s/:story_id/:title/comments/:id" => "comments#redirect_from_short_id"

    get "/s/:id/(:title)" => "stories#show", :as => "story_short_id", :format => /html|json/

    get "/users" => "users#tree", :as => "users_tree"
    get "/~:username" => "users#show", :as => "user", :format => /html|json/
    get "/~:username/standing" => "users#standing", :as => "user_standing"
    get "/~:user/stories(/page/:page)" => "home#newest_by_user", :as => "newest_by_user", :format => /html|json|rss/
    get "/~:user/threads" => "comments#user_threads", :as => "user_threads"
    get "/~:user/comments.rss" => "comments#user_comments", :as => "user_comments", :format => "rss"

    post "/~:username/ban" => "users#ban", :as => "user_ban"
    post "/~:username/unban" => "users#unban", :as => "user_unban"
    post "/~:username/disable_invitation" => "users#disable_invitation",
      :as => "user_disable_invite"
    post "/~:username/enable_invitation" => "users#enable_invitation",
      :as => "user_enable_invite"

    # 2023-07 redirect /u to /~username and /users (for tree)
    get "/u", to: redirect("/users", status: 301)
    get "/u/:username", to: redirect("/~%{username}", status: 301)
    # we don't do /@alice but easy mistake with comments autolinking @alice
    get "/@:username", to: redirect("/~%{username}", status: 301)
    get "/u/:username/standing", to: redirect("~%{username}/standing", status: 301)
    get "/newest/:user", to: redirect("~%{user}/stories", status: 301)
    get "/newest/:user(/page/:page)", to: redirect("~%{user}/stories/page/%{page}", status: 301)
    get "/threads/:user", to: redirect("~%{user}/threads", status: 301)

    get "/avatars/:username_size.png" => "avatars#show", :format => false
    post "/avatars/expire" => "avatars#expire"

    get "/story_image/:short_id.png" => "story_image#show", :as => :story_image, :format => false

    get "/settings" => "settings#index"
    post "/settings" => "settings#update"
    post "/settings/update_avatar_source" => "settings#update_avatar_source", :as => "update_avatar_source"
    post "/settings/deactivate" => "settings#deactivate", :as => "deactivate"
    get "/settings/2fa" => "settings#twofa", :as => "twofa"
    post "/settings/2fa_auth" => "settings#twofa_auth", :as => "twofa_auth"
    get "/settings/2fa_enroll" => "settings#twofa_enroll",
      :as => "twofa_enroll"
    get "/settings/2fa_verify" => "settings#twofa_verify",
      :as => "twofa_verify"
    post "/settings/2fa_update" => "settings#twofa_update",
      :as => "twofa_update"
    post "/settings/pushover_auth" => "settings#pushover_auth"
    get "/settings/pushover_callback" => "settings#pushover_callback"
    get "/settings/mastodon_authentication" => "settings#mastodon_authentication"
    get "/settings/mastodon_auth" => "settings#mastodon_auth"
    get "/settings/mastodon_callback" => "settings#mastodon_callback"
    post "/settings/mastodon_disconnect" => "settings#mastodon_disconnect"
    get "/settings/github_auth" => "settings#github_auth"
    get "/settings/github_callback" => "settings#github_callback"
    post "/settings/github_disconnect" => "settings#github_disconnect"

    get "/filters" => "filters#index"
    post "/filters" => "filters#update"

    get "/tags" => "tags#index", :format => /html|json/

    get "/categories/new" => "categories#new", :as => "new_category"
    get "/categories/:category_name/edit" => "categories#edit", :as => "edit_category"
    get "/categories/:category" => "home#category", :as => :category, :format => /html|json|rss/
    post "/categories" => "categories#create"
    post "/categories/:category_name" => "categories#update", :as => "update_category"

    post "/invitations" => "invitations#create"
    get "/invitations" => "invitations#index"
    get "/invitations/request" => "invitations#build"
    post "/invitations/create_by_request" => "invitations#create_by_request",
      :as => "create_invitation_by_request"
    get "/invitations/confirm/:code" => "invitations#confirm_email"
    post "/invitations/send_for_request" => "invitations#send_for_request",
      :as => "send_invitation_for_request"
    get "/invitations/:invitation_code" => "signup#invited"
    post "/invitations/delete_request" => "invitations#delete_request",
      :as => "delete_invitation_request"

    resources :hat_requests, only: [:index, :new, :create] do
      member do
        post :approve
        post :reject
      end
    end
    resources :hats, only: %i[index edit] do
      member do
        get :doff
        post :doff_by_user
        post :update_in_place
        post :update_by_recreating
      end
    end

    get "/moderations" => "moderations#index"
    get "/moderations/page/:page" => "moderations#index"
    get "/moderators" => "users#tree", :moderators => true

    resources :mod_mails, only: [:index, :show]
    resources :mod_mail_messages, only: :create

    namespace :mod do
      # dashboards
      get "/" => "activities#index", :as => "mod_activity"
      get "flagged_stories/:period" => "flagged#flagged_stories", :as => "flagged_stories"
      get "flagged_comments/:period" => "flagged#flagged_comments", :as => "flagged_comments"
      get "commenters/:period" => "flagged#commenters", :as => "commenters"
      get "hotspots/:period" => "hotspots#index", :as => "hotspots"

      # tools
      get "notes(/:period)", to: redirect("/mod/")
      post "notes" => "notes#create"

      # site data
      resources :comments, only: [:destroy]
      constraints id: DOMAINS_IDENTIFIER do
        resources :domains, only: [:create, :edit, :update]
        patch "/domains_ban/:id" => "domains_ban#update", :as => "ban_domain"
        post "/domains_ban/:id" => "domains_ban#create_and_ban", :as => "create_and_ban_domain"
      end
      constraints identifier: ORIGINS_IDENTIFIER do
        resources :origins, param: :identifier, only: %i[edit]
        patch "/origins_ban/:identifier" => "origins_ban#update", :as => "ban_origin"
        post "/origins_ban/:identifier" => "origins_ban#create_and_ban", :as => "create_and_ban_origin"
      end
      resources :mails, except: [:destroy], as: "mod_mails"
      resources :mail_messages, only: :create, as: "mod_mail_messages"
      resources :reparents, only: [:new, :create]
      resources :stories, only: [:edit, :update] do
        patch "undelete"
        patch "destroy"
      end
      resources :tags, only: [:create, :edit, :new, :update]
    end

    get "/privacy" => "about#privacy"
    get "/about" => "about#about"
    get "/chat" => "about#chat"

    get "/stats" => "stats#index"

    get "/banned-ips" => "banned_ips#index"

    get "/cabinet" => "cabinet#index"
  end

  mount MissionControl::Jobs::Engine, at: "/jobs"
end
