class CategoriasController < ApplicationController
  before_action :set_categoria, only: [ :update, :destroy ]

  def index
    render json: paginate(Categoria.order(:nombre, :id))
  end

  def create
    categoria = Categoria.new(categoria_params)

    if categoria.save
      render json: categoria, status: :created
    else
      render json: { errors: categoria.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @categoria.update(categoria_params)
      render json: @categoria
    else
      render json: { errors: @categoria.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # Categoria tiene has_many :reportes con restrict_with_error: si hay reportes
  # asociados destroy devuelve false, así que no se puede responder 204 a ciegas.
  def destroy
    if @categoria.destroy
      head :no_content
    else
      render json: { errors: [ "No se puede eliminar la categoría porque tiene reportes asociados" ] },
        status: :conflict
    end
  end

  private

  def set_categoria
    @categoria = Categoria.find(params[:id])
  end

  def categoria_params
    params.permit(:nombre, :descripcion)
  end
end
