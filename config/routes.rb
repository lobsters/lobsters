Lobsters::Application.routes.draw do
  root :to => "home#index",
    :protocol => (Rails.env == "production" ? "https://" : "http://")

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

  match "/login/forgot_password" => "login#forgot_password",
    :as => "forgot_password"
  post "/login/reset_password" => "login#reset_password",
    :as => "reset_password"
  match "/login/set_new_password" => "login#set_new_password",
    :as => "set_new_password"

  match "/t/:tag" => "home#tagged", :as => "tag"
  match "/t/:tag/page/:page" => "home#tagged"

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
  post "/comments/post_to/:story_id" => "comments#create"
  post "/comments/preview_to/:story_id" => "comments#preview_new"

  resources :messages do
    post "keep_as_new"
  end

  get "/s/:id/:title/comments/:comment_short_id" => "stories#show_comment"
  get "/s/:id/(:title)" => "stories#show"

  get "/u" => "users#tree"
  get "/u/:id" => "users#show"

  get "/rss" => "home#index", :format => "rss"

  get "/settings" => "settings#index"
  post "/settings" => "settings#update"
  
  get "/filters" => "filters#index"
  post "/filters" => "filters#update"
  
  post "/invitations" => "invitations#create"
  get "/invitations/:invitation_code" => "signup#invited"
  
  get "/moderations" => "moderations#index"
  get "/moderations/page/:page" => "moderations#index"
end
