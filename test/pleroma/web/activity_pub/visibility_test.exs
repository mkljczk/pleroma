# Pleroma: A lightweight social networking server
# Copyright © 2017-2022 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.ActivityPub.VisibilityTest do
  use Pleroma.DataCase, async: true

  alias Pleroma.Activity
  alias Pleroma.Object
  alias Pleroma.Web.ActivityPub.Visibility
  alias Pleroma.Web.CommonAPI
  import Pleroma.Factory

  setup do
    user = insert(:user)
    mentioned = insert(:user)
    following = insert(:user)
    unrelated = insert(:user)
    {:ok, following, user} = Pleroma.User.follow(following, user)
    {:ok, list} = Pleroma.List.create("foo", user)

    Pleroma.List.follow(list, unrelated)

    {:ok, public} =
      CommonAPI.post(user, %{status: "@#{mentioned.nickname}", visibility: "public"})

    {:ok, private} =
      CommonAPI.post(user, %{status: "@#{mentioned.nickname}", visibility: "private"})

    {:ok, direct} =
      CommonAPI.post(user, %{status: "@#{mentioned.nickname}", visibility: "direct"})

    {:ok, unlisted} =
      CommonAPI.post(user, %{status: "@#{mentioned.nickname}", visibility: "unlisted"})

    {:ok, list} =
      CommonAPI.post(user, %{
        status: "@#{mentioned.nickname}",
        visibility: "list:#{list.id}"
      })

    %{
      public: public,
      private: private,
      direct: direct,
      unlisted: unlisted,
      user: user,
      mentioned: mentioned,
      following: following,
      unrelated: unrelated,
      list: list
    }
  end

  test "direct?", %{
    public: public,
    private: private,
    direct: direct,
    unlisted: unlisted,
    list: list
  } do
    assert Visibility.direct?(direct)
    refute Visibility.direct?(public)
    refute Visibility.direct?(private)
    refute Visibility.direct?(unlisted)
    assert Visibility.direct?(list)
  end

  test "public?", %{
    public: public,
    private: private,
    direct: direct,
    unlisted: unlisted,
    list: list
  } do
    refute Visibility.public?(direct)
    assert Visibility.public?(public)
    refute Visibility.public?(private)
    assert Visibility.public?(unlisted)
    refute Visibility.public?(list)
  end

  test "private?", %{
    public: public,
    private: private,
    direct: direct,
    unlisted: unlisted,
    list: list
  } do
    refute Visibility.private?(direct)
    refute Visibility.private?(public)
    assert Visibility.private?(private)
    refute Visibility.private?(unlisted)
    refute Visibility.private?(list)
  end

  test "list?", %{
    public: public,
    private: private,
    direct: direct,
    unlisted: unlisted,
    list: list
  } do
    refute Visibility.list?(direct)
    refute Visibility.list?(public)
    refute Visibility.list?(private)
    refute Visibility.list?(unlisted)
    assert Visibility.list?(list)
  end

  test "visible_for_user? Activity", %{
    public: public,
    private: private,
    direct: direct,
    unlisted: unlisted,
    user: user,
    mentioned: mentioned,
    following: following,
    unrelated: unrelated,
    list: list
  } do
    # All visible to author

    assert Visibility.visible_for_user?(public, user)
    assert Visibility.visible_for_user?(private, user)
    assert Visibility.visible_for_user?(unlisted, user)
    assert Visibility.visible_for_user?(direct, user)
    assert Visibility.visible_for_user?(list, user)

    # All visible to a mentioned user

    assert Visibility.visible_for_user?(public, mentioned)
    assert Visibility.visible_for_user?(private, mentioned)
    assert Visibility.visible_for_user?(unlisted, mentioned)
    assert Visibility.visible_for_user?(direct, mentioned)
    assert Visibility.visible_for_user?(list, mentioned)

    # DM not visible for just follower

    assert Visibility.visible_for_user?(public, following)
    assert Visibility.visible_for_user?(private, following)
    assert Visibility.visible_for_user?(unlisted, following)
    refute Visibility.visible_for_user?(direct, following)
    refute Visibility.visible_for_user?(list, following)

    # Public and unlisted visible for unrelated user

    assert Visibility.visible_for_user?(public, unrelated)
    assert Visibility.visible_for_user?(unlisted, unrelated)
    refute Visibility.visible_for_user?(private, unrelated)
    refute Visibility.visible_for_user?(direct, unrelated)

    # Public and unlisted visible for unauthenticated

    assert Visibility.visible_for_user?(public, nil)
    assert Visibility.visible_for_user?(unlisted, nil)
    refute Visibility.visible_for_user?(private, nil)
    refute Visibility.visible_for_user?(direct, nil)

    # Visible for a list member
    assert Visibility.visible_for_user?(list, unrelated)
  end

  test "visible_for_user? Object", %{
    public: public,
    private: private,
    direct: direct,
    unlisted: unlisted,
    user: user,
    mentioned: mentioned,
    following: following,
    unrelated: unrelated,
    list: list
  } do
    public = Object.normalize(public)
    private = Object.normalize(private)
    unlisted = Object.normalize(unlisted)
    direct = Object.normalize(direct)
    list = Object.normalize(list)

    # All visible to author

    assert Visibility.visible_for_user?(public, user)
    assert Visibility.visible_for_user?(private, user)
    assert Visibility.visible_for_user?(unlisted, user)
    assert Visibility.visible_for_user?(direct, user)
    assert Visibility.visible_for_user?(list, user)

    # All visible to a mentioned user

    assert Visibility.visible_for_user?(public, mentioned)
    assert Visibility.visible_for_user?(private, mentioned)
    assert Visibility.visible_for_user?(unlisted, mentioned)
    assert Visibility.visible_for_user?(direct, mentioned)
    assert Visibility.visible_for_user?(list, mentioned)

    # DM not visible for just follower

    assert Visibility.visible_for_user?(public, following)
    assert Visibility.visible_for_user?(private, following)
    assert Visibility.visible_for_user?(unlisted, following)
    refute Visibility.visible_for_user?(direct, following)
    refute Visibility.visible_for_user?(list, following)

    # Public and unlisted visible for unrelated user

    assert Visibility.visible_for_user?(public, unrelated)
    assert Visibility.visible_for_user?(unlisted, unrelated)
    refute Visibility.visible_for_user?(private, unrelated)
    refute Visibility.visible_for_user?(direct, unrelated)

    # Public and unlisted visible for unauthenticated

    assert Visibility.visible_for_user?(public, nil)
    assert Visibility.visible_for_user?(unlisted, nil)
    refute Visibility.visible_for_user?(private, nil)
    refute Visibility.visible_for_user?(direct, nil)

    # Visible for a list member
    # assert Visibility.visible_for_user?(list, unrelated)
  end

  test "doesn't die when the user doesn't exist",
       %{
         direct: direct,
         user: user
       } do
    Repo.delete(user)
    Pleroma.User.invalidate_cache(user)
    refute Visibility.private?(direct)
  end

  test "get_visibility", %{
    public: public,
    private: private,
    direct: direct,
    unlisted: unlisted,
    list: list
  } do
    assert Visibility.get_visibility(public) == "public"
    assert Visibility.get_visibility(private) == "private"
    assert Visibility.get_visibility(direct) == "direct"
    assert Visibility.get_visibility(unlisted) == "unlisted"
    assert Visibility.get_visibility(list) == "list"
  end

  test "get_visibility with directMessage flag" do
    assert Visibility.get_visibility(%{data: %{"directMessage" => true}}) == "direct"
  end

  test "get_visibility with listMessage flag" do
    assert Visibility.get_visibility(%{data: %{"listMessage" => ""}}) == "list"
  end

  describe "entire_thread_visible_for_user?/2" do
    test "returns false if not found activity", %{user: user} do
      refute Visibility.entire_thread_visible_for_user?(%Activity{}, user)
    end

    test "returns true if activity hasn't 'Create' type", %{user: user} do
      activity = insert(:like_activity)
      assert Visibility.entire_thread_visible_for_user?(activity, user)
    end

    test "returns false when invalid recipients", %{user: user} do
      author = insert(:user)

      activity =
        insert(:note_activity,
          note:
            insert(:note,
              user: author,
              data: %{"to" => ["test-user"]}
            )
        )

      refute Visibility.entire_thread_visible_for_user?(activity, user)
    end

    test "returns true if user following to author" do
      author = insert(:user)
      user = insert(:user)
      Pleroma.User.follow(user, author)

      activity =
        insert(:note_activity,
          note:
            insert(:note,
              user: author,
              data: %{"to" => [user.ap_id]}
            )
        )

      assert Visibility.entire_thread_visible_for_user?(activity, user)
    end
  end
end
