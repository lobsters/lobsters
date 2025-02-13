module CabinetHelper
  def debug_render *args
    capture do
      concat content_tag(:details,
        content_tag(:summary, "header") +
        content_tag(:pre, word_wrap("render #{args.inspect}")),
        style: "margin-left: 20px")
      concat render(*args)
    end
  end

  def as_user user
    @user = user
    yield
    @user = nil
  end
end
