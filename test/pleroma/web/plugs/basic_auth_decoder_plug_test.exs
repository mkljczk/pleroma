# Pleroma: A lightweight social networking server
# Copyright © 2017-2022 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.Plugs.BasicAuthDecoderPlugTest do
  use Pleroma.Web.ConnCase, async: true

  alias Pleroma.Web.Plugs.BasicAuthDecoderPlug

  setup do: clear_config([:auth, :basic_auth], true)

  defp basic_auth_enc(username, password) do
    "Basic " <> Base.encode64("#{username}:#{password}")
  end

  test "it puts the decoded credentials into the assigns", %{conn: conn} do
    header = basic_auth_enc("moonman", "iloverobek")

    conn =
      conn
      |> put_req_header("authorization", header)
      |> BasicAuthDecoderPlug.call(%{})

    assert conn.assigns[:auth_credentials] == %{
             username: "moonman",
             password: "iloverobek"
           }
  end

  test "without a authorization header it doesn't do anything", %{conn: conn} do
    ret_conn =
      conn
      |> BasicAuthDecoderPlug.call(%{})

    assert conn == ret_conn
  end

  test "when disabled it doesn't do anything", %{conn: conn} do
    clear_config([:auth, :basic_auth], false)

    header = basic_auth_enc("moonman", "iloverobek")

    conn =
      conn
      |> put_req_header("authorization", header)
      |> BasicAuthDecoderPlug.call(%{})

    refute conn.assigns[:auth_credentials]
  end
end
