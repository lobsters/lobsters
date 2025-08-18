class CommentHierarchy
  def initialize(comments)
    grouped_by_parent = comments.group_by {|comment| comment.parent_comment_id}
    hierarchy = group_into_hierarchy(grouped_by_parent, nil)
    @hierarchy = hierarchy
  end

  def order_hierarchy_by_confidence_order
    @hierarchy = order_hierarchy_by_confidence_order_recursive(@hierarchy)
    self
  end

  def sort_top_level_comments_by_thread_id_desc
    @hierarchy.sort_by! {|node| node[:parent].thread_id}.reverse!
    self
  end

  def comments
    flatten_hierarchy(@hierarchy)
  end

  private

  def group_into_hierarchy(grouped_by_parent, parent_comment_id)
    return [] unless grouped_by_parent.has_key?(parent_comment_id)

    grouped_by_parent[parent_comment_id].map do |comment|
      {parent: comment, children: group_into_hierarchy(grouped_by_parent, comment.id)}
    end
  end

  def order_hierarchy_by_confidence_order_recursive(children)
    children.sort_by {|hierarchy| hierarchy[:parent].confidence_order}.map do |hierarchy|
      {parent: hierarchy[:parent], children: order_hierarchy_by_confidence_order_recursive(hierarchy[:children])}
    end
  end

  def flatten_hierarchy(hierarchy)
    hierarchy.map do |node|
      [node[:parent]].concat(flatten_hierarchy(node[:children]))
    end.flatten
  end
end
