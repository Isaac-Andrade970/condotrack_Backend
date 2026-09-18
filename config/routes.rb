Rails.application.routes.draw do
  # Health check por defecto de Rails (200 si la app bootea sin excepciones).
  get "up" => "rails/health#show", as: :rails_health_check

  # Health check propio, usado por el pipeline de Jenkins.
  get "health" => "health#show", as: :health

  post "/signup", to: "auth#signup"
  post "/login", to: "auth#login"
  get "/me", to: "auth#me"

  resources :categorias, only: [:index, :create, :update, :destroy]

  resources :reportes, only: [:index, :show, :create, :update, :destroy] do
    # Alexis: agrega aquí el nested resource de comentarios, ej.
    # resources :comentarios, only: [:index, :create, :update, :destroy]
  end
end
