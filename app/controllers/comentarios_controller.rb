class ComentariosController < ApplicationController
  before_action :set_reporte
  before_action :set_comentario, only: [:update, :destroy]

  def index
    render json: @reporte.comentarios.order(created_at: :asc)
  end

  def create
    comentario = @reporte.comentarios.new(comentario_params)
    comentario.usuario = current_user

    if comentario.save
      render json: comentario, status: :created
    else
      render json: { errors: comentario.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @comentario.update(comentario_params)
      render json: @comentario
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
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Reporte no encontrado" }, status: :not_found
  end

  def set_comentario
    @comentario = @reporte.comentarios.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Comentario no encontrado" }, status: :not_found
  end

  def comentario_params
    params.permit(:contenido)
  end
end
