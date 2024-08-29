# typed: false

module PaginationHelper
  def this_page collection
    raise ArgumentError if collection.empty?

    case collection.first
    when Story
      raise
    when Comment
      collection[...Comment::COMMENTS_PER_PAGE]
    end
  end

  def has_next_page collection
    raise ArgumentError if collection.empty?

    collection.size > Comment::COMMENTS_PER_PAGE
  end
end
