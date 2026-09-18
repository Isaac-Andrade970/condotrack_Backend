Rails.application.routes.draw do
  # Health check por defecto de Rails (200 si la app bootea sin excepciones).
  get "up" => "rails/health#show", as: :rails_health_check

  # Health check propio, usado por el pipeline de Jenkins.
  get "health" => "health#show", as: :health

  post "/signup", to: "auth#signup"
  post "/login", to: "auth#login"
  get "/me", to: "auth#me"

  # Los recursos de negocio (reportes, categorias, comentarios) se agregan
  # en las ramas feature/* de cada integrante — no tocar aquí para evitar
  # conflictos de merge entre PRs paralelos.
end
