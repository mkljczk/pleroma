# Pleroma: A lightweight social networking server
# Copyright © 2017-2022 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.AdminAPI.UserController do
  use Pleroma.Web, :controller

  import Pleroma.Web.ControllerHelper,
    only: [fetch_integer_param: 3]

  alias Pleroma.Domain
  alias Pleroma.ModerationLog
  alias Pleroma.User
  alias Pleroma.Web.ActivityPub.Builder
  alias Pleroma.Web.ActivityPub.Pipeline
  alias Pleroma.Web.AdminAPI
  alias Pleroma.Web.AdminAPI.Search
  alias Pleroma.Web.Plugs.OAuthScopesPlug

  @users_page_size 50

  plug(Pleroma.Web.ApiSpec.CastAndValidate, replace_params: false)

  plug(
    OAuthScopesPlug,
    %{scopes: ["admin:read:accounts"]}
    when action in [:index, :show]
  )

  plug(
    OAuthScopesPlug,
    %{scopes: ["admin:write:accounts"]}
    when action in [
           :delete,
           :create,
           :toggle_activation,
           :activate,
           :deactivate,
           :approve,
           :suggest,
           :unsuggest
         ]
  )

  plug(
    OAuthScopesPlug,
    %{scopes: ["admin:write:follows"]}
    when action in [:follow, :unfollow]
  )

  action_fallback(AdminAPI.FallbackController)

  defdelegate open_api_operation(action), to: Pleroma.Web.ApiSpec.Admin.UserOperation

  def delete(%{private: %{open_api_spex: %{params: %{nickname: nickname}}}} = conn, _) do
    conn
    |> do_deletes([nickname])
  end

  def delete(
        %{
          private: %{open_api_spex: %{body_params: %{nicknames: nicknames}}}
        } = conn,
        _
      ) do
    conn
    |> do_deletes(nicknames)
  end

  defp do_deletes(%{assigns: %{user: admin}} = conn, nicknames) when is_list(nicknames) do
    users = Enum.map(nicknames, &User.get_cached_by_nickname/1)

    if Enum.all?(users, &higher_role?(admin, &1)) do
      Enum.each(users, fn user ->
        {:ok, delete_data, _} = Builder.delete(admin, user.ap_id)
        Pipeline.common_pipeline(delete_data, local: true)
      end)

      ModerationLog.insert_log(%{
        actor: admin,
        subject: users,
        action: "delete"
      })

      json(conn, nicknames)
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: dgettext("errors", "Forbidden")})
    end
  end

  # true if actor is greater OR EQUAL in role to target
  defp higher_role?(%User{} = actor, %User{} = target) do
    role_weight(actor) >= role_weight(target)
  end

  defp role_weight(%User{is_admin: true}), do: 2
  defp role_weight(%User{is_moderator: true}), do: 1
  defp role_weight(_), do: 0

  def follow(
        %{
          assigns: %{user: admin},
          private: %{
            open_api_spex: %{
              body_params: %{
                follower: follower_nick,
                followed: followed_nick
              }
            }
          }
        } = conn,
        _
      ) do
    with %User{} = follower <- User.get_cached_by_nickname(follower_nick),
         %User{} = followed <- User.get_cached_by_nickname(followed_nick) do
      User.follow(follower, followed)

      ModerationLog.insert_log(%{
        actor: admin,
        followed: followed,
        follower: follower,
        action: "follow"
      })
    end

    json(conn, "ok")
  end

  def unfollow(
        %{
          assigns: %{user: admin},
          private: %{
            open_api_spex: %{
              body_params: %{
                follower: follower_nick,
                followed: followed_nick
              }
            }
          }
        } = conn,
        _
      ) do
    with %User{} = follower <- User.get_cached_by_nickname(follower_nick),
         %User{} = followed <- User.get_cached_by_nickname(followed_nick) do
      User.unfollow(follower, followed)

      ModerationLog.insert_log(%{
        actor: admin,
        followed: followed,
        follower: follower,
        action: "unfollow"
      })
    end

    json(conn, "ok")
  end

  def create(
        %{
          assigns: %{user: admin},
          private: %{open_api_spex: %{body_params: %{users: users}}}
        } = conn,
        _
      ) do
    changesets =
      users
      |> Enum.map(fn %{nickname: nickname, email: email, password: password} = user ->
        domain_id = Map.get(user, :domain)

        domain =
          if domain_id do
            Domain.get(domain_id)
          end

        user_data = %{
          nickname: nickname,
          name: nickname,
          email: email,
          password: password,
          password_confirmation: password,
          bio: ".",
          domain: domain
        }

        User.register_changeset(%User{}, user_data, need_confirmation: false, from_admin: true)
      end)
      |> Enum.reduce(Ecto.Multi.new(), fn changeset, multi ->
        Ecto.Multi.insert(multi, Ecto.UUID.generate(), changeset)
      end)

    case Pleroma.Repo.transaction(changesets) do
      {:ok, users_map} ->
        users =
          users_map
          |> Map.values()
          |> Enum.map(fn user ->
            {:ok, user} = User.post_register_action(user)

            user
          end)

        ModerationLog.insert_log(%{
          actor: admin,
          subjects: users,
          action: "create"
        })

        render(conn, "created_many.json", users: users)

      {:error, id, changeset, _} ->
        changesets =
          Enum.map(changesets.operations, fn
            {^id, {:changeset, _current_changeset, _}} ->
              changeset

            {_, {:changeset, current_changeset, _}} ->
              current_changeset
          end)

        conn
        |> put_status(:conflict)
        |> render("create_errors.json", changesets: changesets)
    end
  end

  def show(
        %{
          assigns: %{user: admin},
          private: %{open_api_spex: %{params: %{nickname: nickname}}}
        } = conn,
        _
      ) do
    with %User{} = user <- User.get_cached_by_nickname_or_id(nickname, for: admin) do
      render(conn, "show.json", %{user: user})
    else
      _ -> {:error, :not_found}
    end
  end

  def toggle_activation(
        %{assigns: %{user: admin}, private: %{open_api_spex: %{params: %{nickname: nickname}}}} =
          conn,
        _
      ) do
    user = User.get_cached_by_nickname(nickname)

    {:ok, updated_user} = User.set_activation(user, !user.is_active)

    action = if !user.is_active, do: "activate", else: "deactivate"

    ModerationLog.insert_log(%{
      actor: admin,
      subject: [user],
      action: action
    })

    render(conn, "show.json", user: updated_user)
  end

  def activate(
        %{
          assigns: %{user: admin},
          private: %{open_api_spex: %{body_params: %{nicknames: nicknames}}}
        } = conn,
        _
      ) do
    users = Enum.map(nicknames, &User.get_cached_by_nickname/1)
    {:ok, updated_users} = User.set_activation(users, true)

    ModerationLog.insert_log(%{
      actor: admin,
      subject: users,
      action: "activate"
    })

    render(conn, "index.json", users: updated_users)
  end

  def deactivate(
        %{
          assigns: %{user: admin},
          private: %{open_api_spex: %{body_params: %{nicknames: nicknames}}}
        } = conn,
        _
      ) do
    users = Enum.map(nicknames, &User.get_cached_by_nickname/1)
    {:ok, updated_users} = User.set_activation(users, false)

    ModerationLog.insert_log(%{
      actor: admin,
      subject: users,
      action: "deactivate"
    })

    render(conn, "index.json", users: updated_users)
  end

  def approve(
        %{
          assigns: %{user: admin},
          private: %{open_api_spex: %{body_params: %{nicknames: nicknames}}}
        } = conn,
        _
      ) do
    users = Enum.map(nicknames, &User.get_cached_by_nickname/1)
    {:ok, updated_users} = User.approve(users)

    ModerationLog.insert_log(%{
      actor: admin,
      subject: users,
      action: "approve"
    })

    render(conn, "index.json", users: updated_users)
  end

  def suggest(
        %{
          assigns: %{user: admin},
          private: %{open_api_spex: %{body_params: %{nicknames: nicknames}}}
        } = conn,
        _
      ) do
    users = Enum.map(nicknames, &User.get_cached_by_nickname/1)
    {:ok, updated_users} = User.set_suggestion(users, true)

    ModerationLog.insert_log(%{
      actor: admin,
      subject: users,
      action: "add_suggestion"
    })

    render(conn, "index.json", users: updated_users)
  end

  def unsuggest(
        %{
          assigns: %{user: admin},
          private: %{open_api_spex: %{body_params: %{nicknames: nicknames}}}
        } = conn,
        _
      ) do
    users = Enum.map(nicknames, &User.get_cached_by_nickname/1)
    {:ok, updated_users} = User.set_suggestion(users, false)

    ModerationLog.insert_log(%{
      actor: admin,
      subject: users,
      action: "remove_suggestion"
    })

    render(conn, "index.json", users: updated_users)
  end

  def index(%{private: %{open_api_spex: %{params: params}}} = conn, _) do
    {page, page_size} = page_params(params)
    filters = maybe_parse_filters(params[:filters])

    search_params =
      %{
        query: params[:query],
        page: page,
        page_size: page_size,
        tags: params[:tags],
        name: params[:name],
        email: params[:email],
        actor_types: params[:actor_types]
      }
      |> Map.merge(filters)

    with {:ok, users, count} <- Search.user(search_params) do
      render(conn, "index.json", users: users, count: count, page_size: page_size)
    end
  end

  @filters ~w(local external active deactivated need_approval unconfirmed is_admin is_moderator)

  @spec maybe_parse_filters(String.t()) :: %{required(String.t()) => true} | %{}
  defp maybe_parse_filters(filters) when is_nil(filters) or filters == "", do: %{}

  defp maybe_parse_filters(filters) do
    filters
    |> String.split(",")
    |> Enum.filter(&Enum.member?(@filters, &1))
    |> Map.new(&{String.to_existing_atom(&1), true})
  end

  defp page_params(params) do
    {
      fetch_integer_param(params, :page, 1),
      fetch_integer_param(params, :page_size, @users_page_size)
    }
  end
end
