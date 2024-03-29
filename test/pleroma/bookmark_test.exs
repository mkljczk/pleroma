# Pleroma: A lightweight social networking server
# Copyright © 2017-2022 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.BookmarkTest do
  use Pleroma.DataCase, async: true
  import Pleroma.Factory
  alias Pleroma.Bookmark
  alias Pleroma.BookmarkFolder
  alias Pleroma.Web.CommonAPI

  describe "create/3" do
    test "with valid params" do
      user = insert(:user)
      {:ok, activity} = CommonAPI.post(user, %{status: "Some cool information"})
      {:ok, bookmark} = Bookmark.create(user.id, activity.id)
      assert bookmark.user_id == user.id
      assert bookmark.activity_id == activity.id
      assert bookmark.folder_id == nil
    end

    test "with invalid params" do
      {:error, changeset} = Bookmark.create(nil, "")
      refute changeset.valid?

      assert changeset.errors == [
               user_id: {"can't be blank", [validation: :required]},
               activity_id: {"can't be blank", [validation: :required]}
             ]
    end

    test "update existing bookmark folder" do
      user = insert(:user)
      {:ok, activity} = CommonAPI.post(user, %{status: "Some cool information"})

      {:ok, bookmark} = Bookmark.create(user.id, activity.id)
      assert bookmark.folder_id == nil

      {:ok, bookmark_folder} = BookmarkFolder.create(user.id, "Read later")

      {:ok, bookmark} = Bookmark.create(user.id, activity.id, bookmark_folder.id)
      assert bookmark.folder_id == bookmark_folder.id
    end
  end

  describe "destroy/2" do
    test "with valid params" do
      user = insert(:user)

      {:ok, activity} = CommonAPI.post(user, %{status: "Some cool information"})
      {:ok, _bookmark} = Bookmark.create(user.id, activity.id)

      {:ok, _deleted_bookmark} = Bookmark.destroy(user.id, activity.id)
    end
  end

  describe "get/2" do
    test "gets a bookmark" do
      user = insert(:user)

      {:ok, activity} =
        CommonAPI.post(user, %{
          status:
            "Scientists Discover The Secret Behind Tenshi Eating A Corndog Being So Cute – Science Daily"
        })

      {:ok, bookmark} = Bookmark.create(user.id, activity.id)
      assert bookmark == Bookmark.get(user.id, activity.id)
    end
  end
end
