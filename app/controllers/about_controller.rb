class AboutController < ApplicationController
  caches_page :about, :chat, if: CACHE_PAGE
  before_action :show_title_h1

  def four_oh_four
    begin
      @title = "Resource Not Found"
      render :action => "404", :status => 404
    rescue ActionView::MissingTemplate
      render :html => ("<div class=\"box wide\">" <<
        "<h1 class=\"title\">404</h1>" <<
        "Resource not found" <<
        "</div>").html_safe, :layout => "application"
    end
  end

  def about
    begin
      @title = "About"
      render :action => "about"
    rescue ActionView::MissingTemplate
      render :html => ("<div class=\"box wide\">" <<
        "A mystery." <<
        "</div>").html_safe, :layout => "application"
    end
    raise "Seriously, write your own about page." if @homeabout
  end

  def chat
    begin
      @title = "Chat"
      render :action => "chat"
    rescue ActionView::MissingTemplate
      render :html => ("<div class=\"box wide\">" <<
        "<h1 class=\"title\">Chat</h1>" <<
        "Keep it on-site" <<
        "</div>").html_safe, :layout => "application"
    end
  end

  def privacy
    begin
      @title = "Privacy Policy"
      render :action => "privacy"
    rescue ActionView::MissingTemplate
      render :html => ("<div class=\"box wide\">" <<
                      "You apparently have no privacy." <<
                      "</div>").html_safe, :layout => "application"
    end
  end
end
