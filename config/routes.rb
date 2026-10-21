Rails.application.routes.draw do
  # Health check por defecto de Rails (200 si la app bootea sin excepciones).
  get "up" => "rails/health#show", as: :rails_health_check

  # Health check propio, usado por el pipeline de Jenkins.
  get "health" => "health#show", as: :health

  post "/signup", to: "auth#signup"
  post "/login", to: "auth#login"
  get "/me", to: "auth#me"

  resources :categorias, only: [ :index, :create, :update, :destroy ]

  resources :reportes, only: [ :index, :show, :create, :update, :destroy ] do
    resources :comentarios, only: [ :index, :create, :update, :destroy ]
  end

  # Cualquier otra ruta responde 404 en JSON (en vez de cuerpo vacío). Debe ir
  # al final y excluye /rails/* (rutas internas de los engines de Rails).
  match "*path", to: "errors#route_not_found", via: :all,
    constraints: ->(request) { !request.path.start_with?("/rails/") }
end
