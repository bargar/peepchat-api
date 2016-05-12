defmodule Peepchat.SessionController do
  use Peepchat.Web, :controller

  import Ecto.Query, only: [where: 2]
  import Comeonin.Bcrypt
  import Logger

  alias Peepchat.User

  def create(conn, %{"grant_type" => "password",
    "username" => username,
    "password" => password}) do

    try do
      # attempt to retrieve exactly one user from the db, whose email matches
      # the one provided with the login request
      user = User
      |> where(email: ^username)
      |> Repo.one!
      cond do

        checkpw(password, user.password_hash) ->
          # successful login
          Logger.info "User " <> username <> " just logged in"
          # encode a jwt
          { :ok, jwt, _} = Guardian.encode_and_sign(user, :token)
          conn
          |> json(%{access_token: jwt}) # return token to client

        true ->
          # unsuccessful login
          Logger.warning "User " <> username <> " just failed to log in"
          conn
          |> put_status(401)
          |> render(Peepchat.ErrorView, "401.json") #401
      end
    rescue
      e ->
        IO.inspect e # Print error to the console for debugging
        Logger.error "Unexpected error while attempting to log in user " <> username
        conn
        |> put_status(401)
        |> render(Peepchat.ErrorView, "401.json") # 401
    end
  end


  def create(conn, %{"grant_type" => _}) do
    ## handle unknown grant type
    throw "Unsupported grant_type"
  end
end

