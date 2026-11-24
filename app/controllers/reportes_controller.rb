class ReportesController < ApplicationController
  # Campos que solo puede cambiar el autor; el administrador solo cambia el estado.
  CAMPOS_DE_CONTENIDO = %w[titulo descripcion torre_unidad categoria_id].freeze

  before_action :set_reporte, only: [ :show, :update, :destroy ]
  before_action :authorize_update!, only: :update
  before_action -> { authorize_owner!(@reporte) }, only: :destroy

  def index
    render json: paginate(Reporte.order(:created_at, :id))
  end

  def show
    render json: @reporte
  end

  def create
    reporte = current_user.reportes.new(reporte_params)

    if reporte.save
      render json: reporte, status: :created
    else
      render json: { errors: reporte.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @reporte.update(reporte_params)
      render json: @reporte
    else
      render json: { errors: @reporte.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @reporte.destroy
    head :no_content
  end

  private

  def set_reporte
    @reporte = Reporte.find(params[:id])
  end

  # El autor edita todo su reporte. Un administrador ajeno solo puede cambiar el
  # estado (gestión del reporte), no el contenido que escribió el residente.
  def authorize_update!
    return if @reporte.usuario_id == current_user.id
    return authorize_owner!(@reporte) unless current_user.administrador?
    return if (params.keys & CAMPOS_DE_CONTENIDO).empty?

    render_forbidden("Un administrador solo puede cambiar el estado de un reporte ajeno")
  end

  def reporte_params
    params.permit(:titulo, :descripcion, :estado, :torre_unidad, :categoria_id)
  end
end
