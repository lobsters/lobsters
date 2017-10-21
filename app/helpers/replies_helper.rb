module RepliesHelper
  def link_to_filter(name)
    title = name.titleize
    
    if @filter != name
      link_to(title, replies_path(filter: name))
    else
      title
    end
  end
end
