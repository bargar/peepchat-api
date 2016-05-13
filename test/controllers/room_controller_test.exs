defmodule Peepchat.RoomControllerTest do
  use Peepchat.ConnCase

  alias Peepchat.Room
  @valid_attrs %{name: "some content"}
  @invalid_attrs %{}

  defp create_test_rooms(user) do
    #create three rooms owned by logged-in user
    Enum.each ["first room", "second room", "third room"], fn name ->
      Repo.insert! %Peepchat.Room{owner_id: user.id, name: name}
    end

    #create two rooms owned by another user
    other_user = Repo.insert! %Peepchat.User{}
    Enum.each ["fourth room", "fifth room"], fn name ->
      Repo.insert! %Peepchat.Room{owner_id: other_user.id, name: name}
    end
  end

  # run before every test
  setup %{conn: conn} do

    # create a user (bypassing validation)
    user = Repo.insert! %Peepchat.User{}
    # encode a token for the user
    { :ok, jwt, _ } = Guardian.encode_and_sign(user, :token)

    conn = conn
    |> put_req_header("content-type", "application/vnd.api+json") # JSON-API
    |> put_req_header("authorization", "Bearer #{jwt}") # add token to auth header

    {:ok, %{conn: conn, user: user}} # pass user object to each tests
  end

  test "lists all entries on index", %{conn: conn, user: user} do

    # build test rooms
    create_test_rooms(user)

    # list of all rooms
    conn = get conn, room_path(conn, :index)
    assert Enum.count(json_response(conn, 200)["data"]) == 5
  end

  test "lists all entries on index (owner_id = user id", %{conn: conn, user: user} do

    # build test rooms
    create_test_rooms(user)

    # list of rooms owned by user
    conn = get conn, room_path(conn, :index, user_id: user.id)
    assert Enum.count(json_response(conn, 200)["data"]) == 3
  end

  test "shows chosen resource", %{conn: conn, user: user} do
    room = Repo.insert! %Room{owner_id: user.id}
    conn = get conn, room_path(conn, :show, room)
    assert json_response(conn, 200)["data"] == %{
      "id" => to_string(room.id),
      "type" => "room",
      "attributes" => %{
        "name" => room.name
      },
      "relationships" => %{
        "owner" => %{
          "links" => %{
            "related" => "http://localhost:4001/api/user/#{user.id}"
          }
        }
      }
    }
  end

  test "does not show resource and instead throw error when id is nonexistent", %{conn: conn, user: _user} do
    assert_error_sent 404, fn ->
      get conn, room_path(conn, :show, -1)
    end
  end

  test "creates and renders resource when data is valid", %{conn: conn, user: _user} do
    conn = post conn, room_path(conn, :create), data: %{type: "rooms", attributes: @valid_attrs, relationships: %{}}
    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(Room, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn, user: _user} do
    conn = post conn, room_path(conn, :create), data: %{type: "rooms", attributes: @invalid_attrs, relationships: %{}}
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn, user: user} do
    room = Repo.insert! %Room{owner_id: user.id, name: "A room"}
    conn = put conn, room_path(conn, :update, room), data: %{id: room.id, type: "rooms", attributes: @valid_attrs}
    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(Room, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn, user: user} do
    room = Repo.insert! %Room{owner_id: user.id}
    conn = put conn, room_path(conn, :update, room), data: %{id: room.id, type: "rooms", attributes: @invalid_attrs}
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen resource", %{conn: conn, user: user} do
    room = Repo.insert! %Room{owner_id: user.id}
    conn = delete conn, room_path(conn, :delete, room)
    assert response(conn, 204)
    refute Repo.get(Room, room.id)
  end
end
