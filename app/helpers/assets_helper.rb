module AssetsHelper
  def preferred_color_scheme(light, dark, query: nil)
    # To support passing in additional media queries, use an "all" query by default.
    # This will fail entirely in browsers which do not support media queries,
    # but so will nearly all of the CSS (eg no extant browser supports CSS
    # variables but not media queries).
    light_query = "@media all"
    dark_query = "@media (prefers-color-scheme: dark)"
    if query
      light_query = "@media #{query}"
      dark_query += " and #{query}"
    end

    <<-CSS
      #{light_query} {
        :root {
          #{light}
        }
      }

      #{dark_query} {
        html.color-scheme-system {
          #{dark}
        }
      }

      #{light_query} {
        html.color-scheme-dark {
          #{dark}
        }
      }
    CSS
  end
end