class HealthController < ApplicationController
  # Endpoint liviano para el stage "Health Check" del pipeline y monitoreo.
  def show
    render json: { status: "ok", service: "condotrack-backend", time: Time.current.utc.iso8601 }
  end
end
