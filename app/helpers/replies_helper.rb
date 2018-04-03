module RepliesHelper
  def link_to_different_page(text, path)
    if current_page? path
      text
    else
      link_to(text, path)
    end
  end
end
