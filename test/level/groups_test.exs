defmodule Level.GroupsTest do
  use Level.DataCase, async: true

  alias Level.Groups
  alias Level.Groups.Group
  alias Level.Groups.GroupUser

  describe "list_groups_query/2" do
    setup do
      create_user_and_space()
    end

    test "returns a query that includes public non-member groups", %{
      space_user: space_user,
      space: space
    } do
      {:ok, %{group: %Group{id: group_id}}} = create_group(space_user, %{is_public: true})
      {:ok, %{space_user: another_space_user}} = create_space_member(space)
      query = Groups.list_groups_query(another_space_user)
      result = Repo.all(query)
      assert Enum.any?(result, fn group -> group.id == group_id end)
    end

    test "returns a query that includes public member groups", %{space_user: space_user} do
      {:ok, %{group: %Group{id: group_id}}} = create_group(space_user, %{is_public: true})
      query = Groups.list_groups_query(space_user)
      result = Repo.all(query)
      assert Enum.any?(result, fn group -> group.id == group_id end)
    end

    test "returns a query that excludes private non-member groups", %{
      space_user: space_user,
      space: space
    } do
      {:ok, %{group: %Group{id: group_id}}} = create_group(space_user, %{is_private: true})
      {:ok, %{space_user: another_space_user}} = create_space_member(space)
      query = Groups.list_groups_query(another_space_user)
      result = Repo.all(query)
      refute Enum.any?(result, fn group -> group.id == group_id end)
    end
  end

  describe "get_group/2" do
    setup do
      create_user_and_space()
    end

    test "returns the group when public", %{space_user: space_user} do
      {:ok, %{group: %Group{id: group_id}}} = create_group(space_user, %{is_private: false})
      assert {:ok, %Group{id: ^group_id}} = Groups.get_group(space_user, group_id)
    end

    test "does not return the group if it's outside the space", %{space_user: space_user} do
      {:ok, %{space_user: another_space_user}} = create_user_and_space()
      {:ok, %{group: %Group{id: group_id}}} = create_group(space_user, %{is_private: false})
      assert {:error, "Group not found"} = Groups.get_group(another_space_user, group_id)
    end

    test "does not return the group if it's private and user is not a member", %{
      space_user: space_user,
      space: space
    } do
      {:ok, %{space_user: another_space_user}} = create_space_member(space)
      {:ok, %{group: %Group{id: group_id}}} = create_group(space_user, %{is_private: true})
      assert {:error, "Group not found"} = Groups.get_group(another_space_user, group_id)
    end

    test "returns the group if it's private and user is a member", %{
      space_user: space_user,
      space: space
    } do
      {:ok, %{space_user: another_space_user}} = create_space_member(space)

      {:ok, %{group: %Group{id: group_id} = group}} =
        create_group(space_user, %{is_private: true})

      Groups.create_group_membership(group, another_space_user)
      assert {:ok, %Group{id: ^group_id}} = Groups.get_group(another_space_user, group_id)
    end

    test "returns an error if the group does not exist", %{space_user: space_user} do
      assert {:error, "Group not found"} = Groups.get_group(space_user, Ecto.UUID.generate())
    end
  end

  describe "create_group/3" do
    setup do
      create_user_and_space()
    end

    test "creates a group given valid data", %{space_user: space_user} do
      params = valid_group_params()
      {:ok, %{group: group}} = Groups.create_group(space_user, params)

      assert group.name == params.name
      assert group.description == params.description
      assert group.is_private == params.is_private
      assert group.creator_id == space_user.id
      assert group.space_id == space_user.space_id
    end

    test "establishes membership", %{space_user: space_user} do
      params = valid_group_params()
      {:ok, %{group: group}} = Groups.create_group(space_user, params)
      assert Repo.one(GroupUser, space_user_id: space_user.id, group_id: group.id)
    end

    test "returns errors given invalid data", %{space_user: space_user} do
      params = Map.put(valid_group_params(), :name, "")
      {:error, :group, changeset, _} = Groups.create_group(space_user, params)
      assert changeset.errors == [name: {"can't be blank", [validation: :required]}]
    end

    test "returns errors given duplicate name", %{space_user: space_user} do
      params = valid_group_params()
      Groups.create_group(space_user, params)
      {:error, :group, changeset, _} = Groups.create_group(space_user, params)

      assert changeset.errors == [name: {"has already been taken", []}]
    end
  end

  describe "close_group/1" do
    setup do
      create_user_and_space()
    end

    test "transitions open groups to closed", %{space_user: space_user} do
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, closed_group} = Groups.close_group(group)
      assert closed_group.state == "CLOSED"
    end
  end

  describe "get_group_membership/2" do
    setup do
      create_user_and_space()
    end

    test "fetches the group membership if user is a member", %{space_user: space_user} do
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, group_user} = Groups.get_group_membership(group, space_user)
      assert group_user.group_id == group.id
      assert group_user.space_user_id == space_user.id
    end

    test "returns an error if user is not a member", %{space_user: space_user, space: space} do
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{space_user: another_space_user}} = create_space_member(space)

      assert {:error, "The user is a not a group member"} =
               Groups.get_group_membership(group, another_space_user)
    end
  end

  describe "create_group_membership/2" do
    setup do
      create_user_and_space()
    end

    test "establishes a new membership if not already one", %{
      space_user: space_user,
      space: space
    } do
      {:ok, %{group: group}} = create_group(space_user)
      {:ok, %{space_user: another_space_user}} = create_space_member(space)

      {:ok, group_user} = Groups.create_group_membership(group, another_space_user)
      assert group_user.group_id == group.id
      assert group_user.space_user_id == another_space_user.id
    end

    test "returns an error if user is already a member", %{space_user: space_user} do
      {:ok, %{group: group}} = create_group(space_user)

      # The creator of the group is already a member, so...
      {:error, changeset} = Groups.create_group_membership(group, space_user)
      assert changeset.errors == [user: {"is already a member", []}]
    end
  end
end
