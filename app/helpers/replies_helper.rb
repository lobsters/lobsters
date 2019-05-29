module RepliesHelper
  def link_to_filter(name, name_in_url)
    title = name.titleize
    
    if @filter != name_in_url
      link_to(title, replies_path(filter: name_in_url))
    else
      title
    end
  end
end

