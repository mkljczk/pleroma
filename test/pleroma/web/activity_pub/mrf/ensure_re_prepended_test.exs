# Pleroma: A lightweight social networking server
# Copyright © 2017-2022 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.ActivityPub.MRF.EnsureRePrependedTest do
  use Pleroma.DataCase, async: true

  alias Pleroma.Activity
  alias Pleroma.Object
  alias Pleroma.Web.ActivityPub.MRF
  alias Pleroma.Web.ActivityPub.MRF.EnsureRePrepended

  describe "rewrites summary" do
    test "it adds `re:` to summary object when child summary and parent summary equal" do
      message = %{
        "type" => "Create",
        "object" => %{
          "summary" => "object-summary",
          "inReplyTo" => %Activity{object: %Object{data: %{"summary" => "object-summary"}}}
        }
      }

      assert {:ok, res} = EnsureRePrepended.filter(message)
      assert res["object"]["summary"] == "re: object-summary"
    end

    test "it adds `re:` to summary object when child summary contains re-subject of parent summary " do
      message = %{
        "type" => "Create",
        "object" => %{
          "summary" => "object-summary",
          "inReplyTo" => %Activity{object: %Object{data: %{"summary" => "re: object-summary"}}}
        }
      }

      assert {:ok, res} = EnsureRePrepended.filter(message)
      assert res["object"]["summary"] == "re: object-summary"
    end

    test "it adds `re:` to history" do
      message = %{
        "type" => "Create",
        "object" => %{
          "summary" => "object-summary",
          "inReplyTo" => %Activity{object: %Object{data: %{"summary" => "object-summary"}}},
          "formerRepresentations" => %{
            "orderedItems" => [
              %{
                "summary" => "object-summary",
                "inReplyTo" => %Activity{object: %Object{data: %{"summary" => "object-summary"}}}
              }
            ]
          }
        }
      }

      assert {:ok, res} = MRF.filter_one(EnsureRePrepended, message)
      assert res["object"]["summary"] == "re: object-summary"

      assert Enum.at(res["object"]["formerRepresentations"]["orderedItems"], 0)["summary"] ==
               "re: object-summary"
    end

    test "it accepts Updates" do
      message = %{
        "type" => "Update",
        "object" => %{
          "summary" => "object-summary",
          "inReplyTo" => %Activity{object: %Object{data: %{"summary" => "object-summary"}}},
          "formerRepresentations" => %{
            "orderedItems" => [
              %{
                "summary" => "object-summary",
                "inReplyTo" => %Activity{object: %Object{data: %{"summary" => "object-summary"}}}
              }
            ]
          }
        }
      }

      assert {:ok, res} = MRF.filter_one(EnsureRePrepended, message)
      assert res["object"]["summary"] == "re: object-summary"

      assert Enum.at(res["object"]["formerRepresentations"]["orderedItems"], 0)["summary"] ==
               "re: object-summary"
    end
  end

  describe "skip filter" do
    test "it skip if type isn't 'Create' or 'Update'" do
      message = %{
        "type" => "Annotation",
        "object" => %{"summary" => "object-summary"}
      }

      assert {:ok, res} = EnsureRePrepended.filter(message)
      assert res == message
    end

    test "it skip if summary is empty" do
      message = %{
        "type" => "Create",
        "object" => %{
          "inReplyTo" => %Activity{object: %Object{data: %{"summary" => "summary"}}}
        }
      }

      assert {:ok, res} = EnsureRePrepended.filter(message)
      assert res == message
    end

    test "it skip if inReplyTo is empty" do
      message = %{"type" => "Create", "object" => %{"summary" => "summary"}}
      assert {:ok, res} = EnsureRePrepended.filter(message)
      assert res == message
    end

    test "it skip if parent and child summary isn't equal" do
      message = %{
        "type" => "Create",
        "object" => %{
          "summary" => "object-summary",
          "inReplyTo" => %Activity{object: %Object{data: %{"summary" => "summary"}}}
        }
      }

      assert {:ok, res} = EnsureRePrepended.filter(message)
      assert res == message
    end

    test "it skips if the object is only a reference" do
      message = %{
        "type" => "Create",
        "object" => "somereference"
      }

      assert {:ok, res} = EnsureRePrepended.filter(message)
      assert res == message
    end
  end
end
