defmodule Megamove.MembershipsTest do
  use Megamove.DataCase, async: true

  alias Megamove.Memberships
  alias Megamove.Memberships.Membership
  alias Megamove.AccountsFixtures
  alias Megamove.Organizations

  describe "create_membership/1" do
    test "creates a membership with valid data" do
      user = AccountsFixtures.user_fixture()

      {:ok, org} =
        Organizations.create_organization(%{
          name: "Test Org 1",
          slug: "test-org-1",
          org_type: "shipper"
        })

      valid_attrs = %{
        org_id: org.id,
        user_id: user.id,
        org_role: :requester
      }

      assert {:ok, %Membership{} = membership} = Memberships.create_membership(valid_attrs)
      assert membership.org_id == org.id
      assert membership.user_id == user.id
      assert membership.org_role == :requester
    end

    test "validates org_role enum values" do
      {:ok, org} =
        Organizations.create_organization(%{
          name: "Test Org 2",
          slug: "test-org-2",
          org_type: "shipper"
        })

      valid_roles = [:owner, :admin, :dispatcher, :driver, :requester, :viewer]

      for role <- valid_roles do
        test_user = AccountsFixtures.user_fixture()
        attrs = %{org_id: org.id, user_id: test_user.id, org_role: role}
        assert {:ok, %Membership{}} = Memberships.create_membership(attrs)
      end
    end

    test "rejects invalid org_role values" do
      user = AccountsFixtures.user_fixture()

      {:ok, org} =
        Organizations.create_organization(%{
          name: "Test Org 3",
          slug: "test-org-3",
          org_type: "shipper"
        })

      invalid_attrs = %{
        org_id: org.id,
        user_id: user.id,
        org_role: :invalid_role
      }

      assert {:error, %Ecto.Changeset{}} = Memberships.create_membership(invalid_attrs)
    end

    test "enforces unique constraint on org_id and user_id" do
      user = AccountsFixtures.user_fixture()

      {:ok, org} =
        Organizations.create_organization(%{
          name: "Test Org 4",
          slug: "test-org-4",
          org_type: "shipper"
        })

      attrs = %{org_id: org.id, user_id: user.id, org_role: :requester}

      # Create first membership
      assert {:ok, %Membership{}} = Memberships.create_membership(attrs)

      # Try to create duplicate
      assert {:error, %Ecto.Changeset{errors: [org_id: {"has already been taken", _}]}} =
               Memberships.create_membership(attrs)
    end
  end

  describe "add_user_to_organization/3" do
    test "adds user to organization with default requester role" do
      user = AccountsFixtures.user_fixture()

      {:ok, org} =
        Organizations.create_organization(%{
          name: "Test Org 5",
          slug: "test-org-5",
          org_type: "shipper"
        })

      assert {:ok, %Membership{} = membership} =
               Memberships.add_user_to_organization(org.id, user.id)

      assert membership.org_role == :requester
    end

    test "adds user to organization with specified role" do
      user = AccountsFixtures.user_fixture()

      {:ok, org} =
        Organizations.create_organization(%{
          name: "Test Org 6",
          slug: "test-org-6",
          org_type: "shipper"
        })

      assert {:ok, %Membership{} = membership} =
               Memberships.add_user_to_organization(org.id, user.id, :dispatcher)

      assert membership.org_role == :dispatcher
    end
  end
end
