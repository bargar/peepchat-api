defmodule Peepchat.ChangesetView do
  use Peepchat.Web, :view

  @doc """
  Traverses and translates changeset errors.

  See 'Ecto.Changeset.traverse_errors/2` and
  `Peepchat.ErrorHelpers.translate_error/` for more details.
  """

  def translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
  end

  def render("error.json", %{changeset: changeset}) do
    # when encoded, the changeset returns its errors as a JSON object so we just
    # pass it forward
    JaSerializer.EctoErrorSerializer.format(changeset)
  end
end