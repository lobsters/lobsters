# typed: false

Rails.application.routes.draw do
  root to: "home#index",
    protocol: (Rails.application.config.force_ssl ? "https://" : "http://"),
    as: "root"

  get "/404" => "about#four_oh_four", :via => :all

  get "/rss" => "home#index", :format => "rss"
  get "/hottest" => "home#index", :format => "json"

  get "/page/:page" => "home#index"

  get "/active" => "home#active"
  get "/active/page/:page" => "home#active"
  get "/newest" => "home#newest"
  get "/newest/page/:page" => "home#newest"
  get "/recent" => "home#recent"
  get "/recent/page/:page" => "home#recent"
  get "/hidden" => "home#hidden"
  get "/hidden/page/:page" => "home#hidden"

  get "/saved" => "home#saved"
  get "/saved/page/:page" => "home#saved"
  get "/upvoted/stories" => "home#upvoted"
  get "/upvoted/stories/page/:page" => "home#upvoted"
  get "/upvoted/comments" => "comments#upvoted"
  get "/upvoted/comments/page/:page" => "comments#upvoted"
  get "/upvoted", to: redirect("/upvoted/stories")
  get "/upvoted/page/:page", to: redirect("/upvoted/stories/page/%{page}")

  get "/top" => "home#top"
  get "/top/rss" => "home#top", :format => "rss"
  get "/top/page/:page" => "home#top"
  get "/top/:length" => "home#top"
  get "/top/:length/page/:page" => "home#top"

  get "/threads" => "comments#user_threads"

  get "/replies" => "replies#all"
  get "/replies/page/:page" => "replies#all"
  get "/replies/comments" => "replies#comments"
  get "/replies/comments/page/:page" => "replies#comments"
  get "/replies/stories" => "replies#stories"
  get "/replies/stories/page/:page" => "replies#stories"
  get "/replies/unread" => "replies#unread"
  get "/replies/unread/page/:page" => "replies#unread"

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

  get "/t/:tag" => "home#single_tag", :as => "tag", :constraints => {tag: /[^,\.]+/}
  get "/t/:tag" => "home#multi_tag", :as => "multi_tag"
  get "/t/:tag/page/:page" => "home#tagged"

  constraints id: /([^\/]+?)(?=\.json|\.rss|$|\/)/ do
    get "/domain/:id(.:format)", to: redirect("/domains/%{id}")
    get "/domain/:id/page/:page", to: redirect("/domains/%{id}/page/%{page}")
    get "/domains/:id(.:format)" => "home#for_domain", :as => "domain"
    get "/domains/:id/page/:page" => "home#for_domain"
    get "/domains/:id/origins" => "origins#for_domain", :as => "domain_origins"

    resources :domains, only: [:create, :edit, :update]
    patch "/domains_ban/:id" => "domains_ban#update", :as => "ban_domain"
    post "/domains_ban/:id" => "domains_ban#create_and_ban", :as => "create_and_ban_domain"

    # below `resources` so that /edit isn't taken as an identifier
    get "/domains/:id/:author", to: redirect("/origins/%{id}/%{author}")
    get "/domain/:domain/:identifier(.:format)", to: redirect("/domains/%{domain}/%{identifier}")
    get "/domain/:domain/:identifier/page/:page", to: redirect("/domains/%{domain}/%{idetifier}/page/%{page}")
  end

  constraints identifier: /(.+)(?=\.json|\.rss|$|\/)/ do
    # resources :origin, only: [:show, :edit, :update]
    get "/origins/:identifier/edit(.:format)" => "origins#edit", :as => "edit_origin"
    patch "/origins/:identifier" => "origins#update", :as => "update_origin"
    get "/origins/:identifier(.:format)" => "home#for_origin", :as => "origin"
    # leaving out pagination because identifiers (eg 'github.com/alice') can include slashes
    # get "/origins/:identifier/page/:page" => "home#for_domain"
  end

  get "/search" => "search#index"
  get "/search/:q" => "search#index"

  get "/stories/url/all" => "story_urls#all"
  get "/stories/url/latest" => "story_urls#latest"

  resources :stories, except: [:index] do
    get "/stories/:short_id", to: redirect("/s/%{short_id}")
    post "upvote"
    post "flag"
    post "unvote"
    patch "destroy"
    patch "undelete"
    post "hide"
    post "unhide"
    post "save"
    post "unsave"
    post "disown"
    resources :suggestions, only: [:new, :create]

    # Mapping old routes to new routes. can be safely removed after the next deployment
    get "suggest", to: redirect("/stories/suggestions/new", status: 302)
    post "suggest", to: redirect("/stories/suggestions", status: 307)
  end
  post "/stories/fetch_url_attributes", format: "json"
  post "/stories/preview" => "stories#preview"
  post "/stories/check_url_dupe" => "stories#check_url_dupe"

  resources :comments, except: [:new, :destroy] do
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
  get "/comments/page/:page" => "comments#index"
  get "/comments" => "comments#index"

  get "/messages/sent" => "messages#sent"
  get "/messages" => "messages#index"
  post "/messages/batch_delete" => "messages#batch_delete",
    :as => "batch_delete_messages"
  resources :messages do
    post "keep_as_new"
    post "mod_note"
  end

  get "/inbox" => "inbox#index"

  get "/c/:id.json" => "comments#show_short_id", :format => "json"
  get "/c/:id" => "comments#redirect_from_short_id"

  # deprecated
  get "/s/:story_id/:title/comments/:id" => "comments#redirect_from_short_id"

  get "/s/:id/(:title)" => "stories#show"

  get "/users" => "users#tree", :as => "users_tree"
  get "/~:username" => "users#show", :as => "user"
  get "/~:username/standing" => "users#standing", :as => "user_standing"
  get "/~:user/stories(/page/:page)" => "home#newest_by_user", :as => "newest_by_user"
  get "/~:user/threads" => "comments#user_threads", :as => "user_threads"

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

  get "/avatars/:username_size.png" => "avatars#show"
  post "/avatars/expire" => "avatars#expire"

  get "/settings" => "settings#index"
  post "/settings" => "settings#update"
  post "/settings/delete_account" => "settings#delete_account",
    :as => "delete_account"
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

  resources :keybase_proofs, only: [:new, :create, :destroy]
  get "/.well-known/keybase-proof-config" => "keybase_proofs#kbconfig", :as => "keybase_config"

  get "/filters" => "filters#index"
  post "/filters" => "filters#update"

  get "/tags" => "tags#index"
  get "/tags.json" => "tags#index", :format => "json"
  get "/tags/new" => "tags#new", :as => "new_tag"
  get "/tags/:tag_name/edit" => "tags#edit", :as => "edit_tag"
  post "/tags" => "tags#create"
  post "/tags/:tag_name" => "tags#update", :as => "update_tag"

  get "/categories/new" => "categories#new", :as => "new_category"
  get "/categories/:category_name/edit" => "categories#edit", :as => "edit_category"
  get "/categories/:category" => "home#category", :as => :category
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

  resources :hat_requests, except: [:edit] do
    member do
      post :approve
      post :reject
    end
  end
  resources :hats, except: [:new, :update, :destroy] do
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

  get "/mod" => "mod#index"
  get "/mod/flagged_stories/:period" => "mod#flagged_stories", :as => "mod_flagged_stories"
  get "/mod/flagged_comments/:period" => "mod#flagged_comments", :as => "mod_flagged_comments"
  get "/mod/commenters/:period" => "mod#commenters", :as => "mod_commenters"
  get "/mod/notes(/:period)" => "mod_notes#index", :as => "mod_notes"
  post "/mod/notes" => "mod_notes#create"

  namespace :mod do
    resources :reparents, only: [:new, :create]
    resources :stories, only: [:edit, :update] do
      patch "undelete"
      patch "destroy"
    end
  end

  mount MissionControl::Jobs::Engine, at: "/jobs"

  get "/privacy" => "about#privacy"
  get "/about" => "about#about"
  get "/chat" => "about#chat"

  get "/stats" => "stats#index"

  get "/cabinet" => "cabinet#index"

  post "/csp-violation-report" => "csp#violation_report"
end
