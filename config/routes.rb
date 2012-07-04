Lobsters::Application.routes.draw do
  root :to => "home#index",
    :protocol => (Rails.env == "production" ? "https://" : "http://")

  get "/newest(.format)" => "home#newest"

  get "/threads" => "comments#threads"

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

  resources :stories do
    post "upvote"
    post "downvote"
    post "unvote"
    post "undelete"
  end
  post "/stories/fetch_url_title" => "stories#fetch_url_title"
  
  resources :comments do
    post "upvote"
    post "downvote"
    post "unvote"
  end
  post "/comments/:story_id" => "comments#create"
  post "/comments/preview/:story_id" => "comments#preview"

  resources :messages do
    post "keep_as_new"
  end

  get "/s/:id/:title/comments/:comment_short_id" => "stories#show_comment"
  get "/s/:id/(:title)" => "stories#show"
  get "/u/:id" => "users#show"

  get "/rss" => "home#index", :format => "rss"

  get "/settings" => "settings#index"
  post "/settings" => "settings#update"
  
  post "/invitations" => "invitations#create"
  get "/invitations/:invitation_code" => "signup#invited"
end
