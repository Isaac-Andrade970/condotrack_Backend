class ErrorsController < ApplicationController
  skip_before_action :authenticate_request

  def route_not_found
    render json: { error: "Ruta no encontrada: #{request.method} #{request.path}" }, status: :not_found
  end
end
