Rails.application.routes.draw do
  resource :session, only: %i[create]
  resources :transactions, only: %i[index create]
end
