Rails.application.routes.draw do
  root 'flights#index'

  get '/flights' => 'flights#index'
  get '/delete_all' => 'flights#destroy_all'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
