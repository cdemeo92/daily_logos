defmodule DailyLogos.Accounts.UserIdentity do
  use Ecto.Schema
  import Ecto.Changeset

  @providers ~w(facebook github google)

  schema "user_identities" do
    field :provider, :string
    field :provider_uid, :string
    belongs_to :user, DailyLogos.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(identity, attrs) do
    identity
    |> cast(attrs, [:provider, :provider_uid, :user_id])
    |> validate_required([:provider, :provider_uid, :user_id])
    |> validate_inclusion(:provider, @providers)
    |> validate_length(:provider_uid, max: 255)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:provider, :provider_uid],
      name: :user_identities_provider_provider_uid_index
    )
  end
end
