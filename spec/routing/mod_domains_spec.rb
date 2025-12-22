# typed: false

require "rails_helper"

describe "domains routing", type: :routing do
  it "#edit" do
    expect(get("/mod/domains/github.com/edit")).to route_to(
      controller: "mod/domains",
      action: "edit",
      id: "github.com"
    )
  end

  it "#update" do
    expect(patch("/mod/domains/github.com")).to route_to(
      controller: "mod/domains",
      action: "update",
      id: "github.com"
    )
  end
end

describe "domains_ban routing", type: :routing do
  it "#create_and_ban" do
    expect(post("/mod/domains_ban/github.com")).to route_to(
      controller: "mod/domains_ban",
      action: "create_and_ban",
      id: "github.com"
    )
  end

  it "#update" do
    expect(patch("/mod/domains_ban/github.com")).to route_to(
      controller: "mod/domains_ban",
      action: "update",
      id: "github.com"
    )
  end
end
