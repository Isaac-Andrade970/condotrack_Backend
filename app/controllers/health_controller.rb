class HealthController < ApplicationController
  skip_before_action :authenticate_request, only: [ :show ]

  # Endpoint liviano para el stage "Health Check" del pipeline y monitoreo.
  def show
    render json: { status: "ok", service: "condotrack-backend", time: Time.current.utc.iso8601 }
  end
end
