require "rails_helper"

describe "domains routing", type: :routing do
  it "#create" do
    expect(post("/mod/domains")).to route_to(
      controller: "mod/domains",
      action: "create",
      format: "html"
    )
  end

  it "#edit" do
    expect(get("/mod/domains/github.com/edit")).to route_to(
      controller: "mod/domains",
      action: "edit",
      id: "github.com",
      format: "html"
    )
  end

  it "#update" do
    expect(patch("/mod/domains/github.com")).to route_to(
      controller: "mod/domains",
      action: "update",
      id: "github.com",
      format: "html"
    )
  end
end

describe "domains_ban routing", type: :routing do
  it "#create_and_ban" do
    expect(post("/mod/domains_ban/github.com")).to route_to(
      controller: "mod/domains_ban",
      action: "create_and_ban",
      id: "github.com",
      format: "html"
    )
  end

  it "#update" do
    expect(patch("/mod/domains_ban/github.com")).to route_to(
      controller: "mod/domains_ban",
      action: "update",
      id: "github.com",
      format: "html"
    )
  end
end
