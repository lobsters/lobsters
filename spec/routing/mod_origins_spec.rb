# typed: false

require "rails_helper"

describe "mod origin routing", type: :routing do
  it "#edit with an identifier with a slash" do
    expect(get("/mod/origins/github.com/alice/edit")).to route_to(
      controller: "mod/origins",
      action: "edit",
      identifier: "github.com/alice"
    )
  end
end

describe "mod origins_ban routing", type: :routing do
  it "#create_and_ban with an identifier with a slash" do
    expect(post("/mod/origins_ban/github.com/alice")).to route_to(
      controller: "mod/origins_ban",
      action: "create_and_ban",
      identifier: "github.com/alice"
    )
  end

  it "#update with an identifier with a slash" do
    expect(patch("/mod/origins_ban/github.com/alice")).to route_to(
      controller: "mod/origins_ban",
      action: "update",
      identifier: "github.com/alice"
    )
  end
end
