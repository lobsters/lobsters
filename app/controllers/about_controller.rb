class AboutController < ApplicationController
  caches_page :about, :chat, if: CACHE_PAGE
  before_action :show_title_h1, except: [:four_oh_four]

  def four_oh_four
    @title = "Resource Not Found"
    render action: "404", status: 404
  rescue ActionView::MissingTemplate
    render status: 404, html: (
      "<h1>404</h1><p>Resource not found</p>"
    ).html_safe, layout: 'application'
  end

  def about
    begin
      @title = "About"
      render action: "about"
    rescue ActionView::MissingTemplate
      render layout: 'application', html: ("<h1>A mystery.")
    end
    raise "Seriously, write your own about page." if @homeabout
  end

  def chat
    begin
      @title = "Chat"
      render action: "chat"
    rescue ActionView::MissingTemplate
      render html: ("<h1>Don't speak. I know what you're thinking.</h1>"),
        layout: 'application'
    end
  end

  def privacy
    begin
      @title = "Privacy Policy"
      render action: "privacy"
    rescue ActionView::MissingTemplate
      render layout: 'application', html: <<-HTML
        <blockquote>You have zero privacy anyway. Get over it.</blockquote>
        <p>Scott McNealy</p>
      HTML
    end
  end
end
