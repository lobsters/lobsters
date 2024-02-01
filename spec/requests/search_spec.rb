# typed: false

require "rails_helper"

RSpec.describe "search controller", type: :request do
  it "loads the search form" do
    get "/search"
    expect(response).to be_successful
  end

  it "can find zero hits" do
    get "/search", params: {q: "aaa"}

    expect(response).to be_successful
    expect(response.body).to include("0 results")
  end

  it "doesn't allow sql injection" do
    # real query that threw a 500 in prod
    get "/search", params: {q: "tag:formalmethods tag:testing') AND EXTRACTVALUE(4050,CONCAT(0x5c,0x7170787171,(SELECT (ELT(4050=4050,1))),0x71627a6b71)) AND ('pDUW'='pDUW", what: "stories", order: "newest"}

    expect(response).to be_successful
    expect(response.body).to include("0 results")
  end

  it "doesn't serve to searx" do
    get "/search?utf8=%E2%9C%93&q=query&what=stories&order=relevance"

    expect(response).to be_successful
    expect(response.body).to include("0 results")
  end
end
