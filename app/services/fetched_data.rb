class FetchedData
  attr_accessor :url, :title, :descrition

  def initialize(url: nil, title: nil, description: nil)
    @url = url
    @title = title
    @description = description
  end
end
