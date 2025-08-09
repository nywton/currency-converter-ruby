Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resource :session, only: %i[create]
      resources :transactions, only: %i[index create]
    end
  end
end
