module CabinetHelper
  def debug_render *args
    capture do
      concat render(*args)
      concat content_tag(:pre, "render #{args.join(" ")}")
    end
  end
end
