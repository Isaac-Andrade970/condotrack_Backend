class ApplicationController < ActionController::API
  DEFAULT_PER_PAGE = 20
  MAX_PER_PAGE = 100

  before_action :authenticate_request

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionDispatch::Http::Parameters::ParseError, with: :render_invalid_json

  attr_reader :current_user

  private

  def authenticate_request
    header = request.headers["Authorization"]
    token = header.split(" ").last if header

    decoded = JsonWebToken.decode(token)
    @current_user = User.find(decoded[:user_id])
  rescue ActiveRecord::RecordNotFound, JWT::DecodeError, JWT::ExpiredSignature
    render json: { error: "No autorizado" }, status: :unauthorized
  end

  # Solo el autor (usuario_id) puede modificar o eliminar su reporte/comentario.
  def authorize_owner!(record)
    return if record.usuario_id == current_user.id

    render json: { error: "No tienes permiso para modificar este recurso" }, status: :forbidden
  end

  # Paginación opcional: sin ?page ni ?per_page devuelve todo (compatible con el
  # frontend actual); con ellos devuelve la página y el total en X-Total-Count.
  def paginate(scope)
    return scope unless params[:page].present? || params[:per_page].present?

    page = [ params[:page].to_i, 1 ].max
    per_page = params.fetch(:per_page, DEFAULT_PER_PAGE).to_i.clamp(1, MAX_PER_PAGE)

    response.set_header("X-Total-Count", scope.count.to_s)
    scope.offset((page - 1) * per_page).limit(per_page)
  end

  def render_not_found(exception)
    render json: { error: "No se encontró el recurso solicitado (#{exception.model || 'desconocido'})" }, status: :not_found
  end

  def render_invalid_json
    render json: { error: "El cuerpo de la petición no es un JSON válido" }, status: :bad_request
  end
end
