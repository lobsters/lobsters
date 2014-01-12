Lobsters::Application.routes.draw do
  root :to => "home#index",
    :protocol => (Rails.env == "production" ? "https://" : "http://")

  get "/rss" => "home#index", :format => "rss"
  get "/hottest.json" => "home#index", :format => "json"

  get "/page/:page" => "home#index"

  get "/newest(.format)" => "home#newest"
  get "/newest/page/:page" => "home#newest"
  get "/newest/:user" => "home#newest_by_user"
  get "/newest/:user/page/:page" => "home#newest_by_user"

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

  get "/t/:tag" => "home#tagged", :as => "tag"
  get "/t/:tag/page/:page" => "home#tagged"

  get "/search" => "search#index"

  resources :stories do
    post "upvote"
    post "downvote"
    post "unvote"
    post "undelete"
  end
  post "/stories/fetch_url_title" => "stories#fetch_url_title"
  post "/stories/preview" => "stories#preview"

  resources :comments do
    post "upvote"
    post "downvote"
    post "unvote"

    post "edit"
    post "preview"
    post "update"
    post "delete"
    post "undelete"
  end
  get "/comments/page/:page" => "comments#index"
  post "/comments/post_to/:story_id" => "comments#create"
  post "/comments/preview_to/:story_id" => "comments#preview_new"

  get "/messages/sent" => "messages#sent"
  resources :messages do
    post "keep_as_new"
  end

  get "/s/:id/:title/comments/:comment_short_id" => "stories#show_comment"
  get "/s/:id/(:title)" => "stories#show"

  get "/u" => "users#tree"
  get "/u/:id" => "users#show", :as => "user"

  get "/settings" => "settings#index"
  post "/settings" => "settings#update"

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

  get "/moderations" => "moderations#index"
  get "/moderations/page/:page" => "moderations#index"

  get "/privacy" => "home#privacy"
  get "/about" => "home#about"
end
