Lobsters::Application.routes.draw do
  root :to => "home#index"

  get "login" => "login#index"
  post "login" => "login#login"
  post "logout" => "login#logout"

  get "signup" => "signup#index"
  post "signup" => "signup#signup"

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

  get "/p/:id/(:title)" => "stories#show"
end
