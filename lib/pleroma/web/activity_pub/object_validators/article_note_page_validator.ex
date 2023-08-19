# Pleroma: A lightweight social networking server
# Copyright © 2017-2022 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.ActivityPub.ObjectValidators.ArticleNotePageValidator do
  use Ecto.Schema

  alias Pleroma.EctoType.ActivityPub.ObjectValidators
  alias Pleroma.Web.ActivityPub.ObjectValidators.CommonFixes
  alias Pleroma.Web.ActivityPub.ObjectValidators.CommonValidations
  alias Pleroma.Web.ActivityPub.Transmogrifier

  import Ecto.Changeset

  @primary_key false
  @derive Jason.Encoder

  embedded_schema do
    quote do
      unquote do
        import Elixir.Pleroma.Web.ActivityPub.ObjectValidators.CommonFields
        message_fields()
        object_fields()
        status_object_fields()
      end
    end

    field(:replies, {:array, ObjectValidators.ObjectID}, default: [])
  end

  def cast_and_apply(data, meta \\ []) do
    data
    |> cast_data(meta)
    |> apply_action(:insert)
  end

  def cast_and_validate(data, meta \\ []) do
    data
    |> cast_data(meta)
    |> validate_data()
  end

  def cast_data(data, meta \\ []) do
    %__MODULE__{}
    |> changeset(data, meta)
  end

  defp fix_url(%{"url" => url} = data) when is_bitstring(url), do: data
  defp fix_url(%{"url" => url} = data) when is_map(url), do: Map.put(data, "url", url["href"])
  defp fix_url(data), do: data

  defp fix_tag(%{"tag" => tag} = data) when is_list(tag) do
    Map.put(data, "tag", Enum.filter(tag, &is_map/1))
  end

  defp fix_tag(%{"tag" => tag} = data) when is_map(tag), do: Map.put(data, "tag", [tag])
  defp fix_tag(data), do: Map.drop(data, ["tag"])

  defp fix_replies(%{"replies" => %{"first" => %{"items" => replies}}} = data)
       when is_list(replies),
       do: Map.put(data, "replies", replies)

  defp fix_replies(%{"replies" => %{"items" => replies}} = data) when is_list(replies),
    do: Map.put(data, "replies", replies)

  # TODO: Pleroma does not have any support for Collections at the moment.
  # If the `replies` field is not something the ObjectID validator can handle,
  # the activity/object would be rejected, which is bad behavior.
  defp fix_replies(%{"replies" => replies} = data) when not is_list(replies),
    do: Map.drop(data, ["replies"])

  defp fix_replies(data), do: data

  defp fix_quote_url(%{"quoteUrl" => _quote_url} = data), do: data

  # Fedibird
  # https://github.com/fedibird/mastodon/commit/dbd7ae6cf58a92ec67c512296b4daaea0d01e6ac
  defp fix_quote_url(%{"quoteUri" => quote_url} = data) do
    Map.put(data, "quoteUrl", quote_url)
  end

  # Old Fedibird (bug)
  # https://github.com/fedibird/mastodon/issues/9
  defp fix_quote_url(%{"quoteURL" => quote_url} = data) do
    Map.put(data, "quoteUrl", quote_url)
  end

  # Misskey fallback
  defp fix_quote_url(%{"_misskey_quote" => quote_url} = data) do
    Map.put(data, "quoteUrl", quote_url)
  end

  defp fix_quote_url(data), do: data

  def fix_attachments(%{"attachment" => attachment} = data) when is_map(attachment),
    do: Map.put(data, "attachment", [attachment])

  def fix_attachments(data), do: data

  defp fix(data, meta) do
    data
    |> CommonFixes.fix_actor()
    |> CommonFixes.fix_object_defaults()
    |> fix_url()
    |> fix_tag()
    |> fix_replies()
    |> fix_quote_url()
    |> fix_attachments()
    |> CommonFixes.fix_quote_url()
    |> Transmogrifier.fix_emoji()
    |> Transmogrifier.fix_content_map()
    |> CommonFixes.maybe_add_language(meta)
    |> CommonFixes.maybe_add_content_map()
  end

  def changeset(struct, data, meta \\ []) do
    data = fix(data, meta)

    struct
    |> cast(data, __schema__(:fields) -- [:attachment, :tag])
    |> cast_embed(:attachment)
    |> cast_embed(:tag)
  end

  defp validate_data(data_cng) do
    data_cng
    |> validate_inclusion(:type, ["Article", "Note", "Page"])
    |> validate_required([:id, :actor, :attributedTo, :type, :context])
    |> CommonValidations.validate_any_presence([:cc, :to])
    |> CommonValidations.validate_fields_match([:actor, :attributedTo])
    |> CommonValidations.validate_actor_presence()
    |> CommonValidations.validate_host_match()
  end
end
