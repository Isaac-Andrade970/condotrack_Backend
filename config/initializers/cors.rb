# Be sure to restart your server when you modify this file.

# Orígenes autorizados a llamar a la API desde un navegador. Se pueden
# sobrescribir con la variable de entorno CORS_ORIGINS (lista separada por comas).
# Dominios: frontend en Vercel, frontend del docente y Vite en desarrollo local.
allowed_origins = ENV.fetch(
  "CORS_ORIGINS",
  "https://condotrackfrontend.vercel.app,https://condotrack.frubilarz.cl,http://localhost:5173"
).split(",").map(&:strip)

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*allowed_origins)

    resource "*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      expose: [ "X-Total-Count" ]
  end
end
