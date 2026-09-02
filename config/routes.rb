Rails.application.routes.draw do
  # Health check por defecto de Rails (200 si la app bootea sin excepciones).
  get "up" => "rails/health#show", as: :rails_health_check

  # Health check propio, usado por el pipeline de Jenkins.
  get "health" => "health#show", as: :health
end
