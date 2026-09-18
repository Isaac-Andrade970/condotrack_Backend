class AuthController < ApplicationController
  skip_before_action :authenticate_request, only: [:signup, :login]

  def signup
    user = User.new(user_params)

    if user.save
      token = JsonWebToken.encode(user_id: user.id)
      render json: { token:, user: user_response(user) }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def login
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      token = JsonWebToken.encode(user_id: user.id)
      render json: { token:, user: user_response(user) }, status: :ok
    else
      render json: { error: "Credenciales inválidas" }, status: :unauthorized
    end
  end

  def me
    render json: user_response(current_user)
  end

  private

  def user_params
    params.permit(:email, :password, :nombre)
  end

  def user_response(user)
    { id: user.id, email: user.email, nombre: user.nombre }
  end
end
