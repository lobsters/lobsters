Lobsters::Application.routes.draw do
  scope :format => "html" do
    root :to => "home#index",
      :protocol => (Rails.application.config.force_ssl ? "https://" : "http://"),
      :as => "root"

    get "/rss" => "home#index", :format => "rss"
    get "/hottest" => "home#index", :format => "json"

    get "/page/:page" => "home#index"

    get "/newest" => "home#newest", :format => /html|json|rss/
    get "/newest/page/:page" => "home#newest"
    get "/newest/:user" => "home#newest_by_user"
    get "/newest/:user/page/:page" => "home#newest_by_user"
    get "/recent" => "home#recent"
    get "/recent/page/:page" => "home#recent"
    get "/hidden" => "home#hidden"
    get "/hidden/page/:page" => "home#hidden"

    get "/upvoted(.format)" => "home#upvoted"
    get "/upvoted/page/:page" => "home#upvoted"

    get "/top" => "home#top"
    get "/top/page/:page" => "home#top"
    get "/top/:length" => "home#top"
    get "/top/:length/page/:page" => "home#top"

    get "/threads" => "comments#threads"
    get "/threads/:user" => "comments#threads"

    get "/login" => "login#index"
    post "/login" => "login#login"
    post "/logout" => "login#logout"

    get "/signup" => "signup#index"
    post "/signup" => "signup#signup"
    get "/signup/invite" => "signup#invite"

    get "/login/forgot_password" => "login#forgot_password",
      :as => "forgot_password"
    post "/login/reset_password" => "login#reset_password",
      :as => "reset_password"
    match "/login/set_new_password" => "login#set_new_password",
      :as => "set_new_password", :via => [:get, :post]

    get "/t/:tag" => "home#tagged", :as => "tag", :format => /html|rss/
    get "/t/:tag/page/:page" => "home#tagged"

    get "/search" => "search#index"

    resources :stories do
      post "upvote"
      post "downvote"
      post "unvote"
      post "undelete"
      post "hide"
      post "unhide"
    end
    post "/stories/fetch_url_title", :format => "json"
    post "/stories/preview" => "stories#preview"

    resources :comments do
      member do
        get "reply"
        post "upvote"
        post "downvote"
        post "unvote"

        post "delete"
        post "undelete"
      end
    end
    get "/comments/page/:page" => "comments#index"

    get "/messages/sent" => "messages#sent"
    post "/messages/batch_delete" => "messages#batch_delete",
      :as => "batch_delete_messages"
    resources :messages do
      post "keep_as_new"
    end

    get "/s/:id/:title/comments/:comment_short_id" => "stories#show"
    get "/s/:id/(:title)" => "stories#show", :format => /html|json/

    get "/u" => "users#tree"
    get "/u/:username" => "users#show", :as => "user"

    get "/settings" => "settings#index"
    post "/settings" => "settings#update"
    post "/settings/pushover" => "settings#pushover"
    get "/settings/pushover_callback" => "settings#pushover_callback"
    post "/settings/delete_account" => "settings#delete_account",
      :as => "delete_account"

    get "/filters" => "filters#index"
    post "/filters" => "filters#update"

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

    get "/moderations" => "moderations#index"
    get "/moderations/page/:page" => "moderations#index"

    get "/privacy" => "home#privacy"
    get "/about" => "home#about"

    get "/resettraffic" => "home#resettraffic"
  end
end
