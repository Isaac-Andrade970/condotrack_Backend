class ReportesController < ApplicationController
  before_action :set_reporte, only: [ :show, :update, :destroy ]
  before_action -> { authorize_owner!(@reporte) }, only: [ :update, :destroy ]

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

  def reporte_params
    params.permit(:titulo, :descripcion, :estado, :torre_unidad, :categoria_id)
  end
end
