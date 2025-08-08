Rails.application.routes.draw do
  resource :session, only: %i[create]
end
