Rails.application.routes.draw do
  resource :session, only: %i[create]

  # get  "transactions", to: "list_transactions#index",   as: :transactions
  post "transactions", to: "create_transactions#create", as: :transactions
end
