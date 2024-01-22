defmodule BlogNew.BlogTest do
  use BlogNew.DataCase

  alias BlogNew.Blog
  alias BlogNew.Blog.Post

  doctest Post

  describe "posts" do
    @valid_attrs %{
      markdown_filename: "1.md",
      title: "some title",
      content: "test",
      plain_content: "test",
      draft: false,
      publish_date: ~D[2023-01-01]
    }

    def post_fixture(attrs \\ %{}) do
      attrs = Enum.into(attrs, @valid_attrs)

      {:ok, post} =
        Post.changeset(%Post{}, attrs)
        |> Repo.insert()

      post
    end

    test "list_posts!/0 returns all posts" do
      post = post_fixture()
      assert Blog.list_posts!() == [post]
    end

    test "get_post!/1 returns the post with given id" do
      post = post_fixture()
      assert Blog.get_post!(1) == post
    end
  end
end
