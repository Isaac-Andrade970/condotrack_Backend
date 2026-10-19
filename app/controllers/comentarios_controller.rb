class ComentariosController < ApplicationController
  before_action :set_reporte
  before_action :set_comentario, only: [ :update, :destroy ]
  before_action -> { authorize_owner!(@comentario) }, only: [ :update, :destroy ]

  # includes(:usuario) carga los autores en una sola consulta (evita N+1 al
  # serializar usuario_nombre).
  def index
    comentarios = paginate(@reporte.comentarios.includes(:usuario).order(:created_at, :id))
    render json: comentarios.map(&:as_json_with_author)
  end

  def create
    comentario = @reporte.comentarios.new(comentario_params)
    comentario.usuario = current_user

    if comentario.save
      render json: comentario.as_json_with_author, status: :created
    else
      render json: { errors: comentario.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @comentario.update(comentario_params)
      render json: @comentario.as_json_with_author
    else
      render json: { errors: @comentario.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @comentario.destroy
    head :no_content
  end

  private

  def set_reporte
    @reporte = Reporte.find(params[:reporte_id])
  end

  def set_comentario
    @comentario = @reporte.comentarios.find(params[:id])
  end

  def comentario_params
    params.permit(:contenido)
  end
end
