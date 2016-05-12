defmodule Peepchat.UserTest do
  use Peepchat.ModelCase

  alias Peepchat.User

  @valid_attrs %{email: "j@example.com", password: "foo12345", password_confirmation: "foo12345"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = User.changeset(%User{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = User.changeset(%User{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "mis-matched password_confirmation doesn't work" do
    changeset = User.changeset(%User{}, %{email: "j@example.com",
      password: "d1asf56ds4f",
      password_confirmation: "asdlfsadjfds"})
    refute changeset.valid?
  end

  test "missing password confirmation doesn't work" do
      changeset = User.changeset(%User{}, %{email: "j@example.com",
        password: "d1asf56ds4f"})
      refute changeset.valid?
  end

  test "short password doesn't work" do
      changeset = User.changeset(%User{}, %{email: "j@example.com",
        password: "abc",
        password_confirmation: "abc"})
      refute changeset.valid?
    end
end
