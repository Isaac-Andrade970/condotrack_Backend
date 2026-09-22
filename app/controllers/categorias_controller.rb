class CategoriasController < ApplicationController
  before_action :set_categoria, only: [:update, :destroy]

  def index
    render json: Categoria.all
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

  def destroy
    @categoria.destroy
    head :no_content
  end

  private

  def set_categoria
    @categoria = Categoria.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Categoría no encontrada" }, status: :not_found
  end

  def categoria_params
    params.permit(:nombre, :descripcion)
  end
end
