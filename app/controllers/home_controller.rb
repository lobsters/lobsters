class HomeController < ApplicationController
  # for rss feeds, load the user's tag filters if a token is passed
  before_filter :find_user_from_rss_token, :only => [ :index, :newest ]
  before_filter { @page = page }
  before_filter :require_logged_in_user, :only => [ :upvoted ]

  def about
    begin
      @title = I18n.t 'controllers.home_controller.abouttitle'
      render :action => "about"
    rescue
      render :text => "<h2>Le Journal du hacker</h2><div class=\"box wide\">" <<
        "Le <a href=\"/\">Journal du hacker</a> a pour ambition de présenter l'activité des hackers francophones, du mouvement du Logiciel Libre et open source en langue française, mais aussi des startups et du mouvement entrepreunariale de la communauté francophone.<br />Le Journal du hacker s'inspire directement du site anglophone <a href=\"https://news.ycombinator.com\">Hacker News</a> car l'idée de base est excellente mais propose d'aller plus loin en offrant un moteur <a href=\"https://github.com/carlchenet/lobsters\">basé sur un logiciel libre</a> fonctionnant par cooptation afin de créer une vraie communauté responsable. Il suffit de <a href=\"/invitations/request\">demander une invitation</a> pour nous rejoindre et partager vos infos avec nous ;)<br /></div><h2>Les acteurs du Journal du hacker</h2><div class=\"box wide\">En tant que <strong>lecteur</strong> vous avez accès au <a href=\"/\">site</a> et vous pourrez :<ul><li>Lire les <a href=\"/comments\">commentaires</a> sans toutefois pouvoir y participer</li><li>Suivre la publication des articles via <a href=\"/rss\">RSS</a>, <a href=\"https://twitter.com/journalduhacker\">Twitter</a> ou <a href=\"https://framasphere.org/people/2aaaaba0110c0133c7ea2a0000053625\">Diaspora</a></li><li>Suivre uniquement les marques (tags) qui vous intéressent par RSS exemple <a href=\"/t/conteneurs.rss\">Conteneurs</a>, il suffit de se rendre sur <a href=\"/filters\">Filtres</a> de cliquer sur une marque et de rajouter .rss sur l'URL ainsi <a href=\"/t/linux\">https://www.journalduhacker.net/t/linux</a> devient <a href=\"/t/linux.rss\">https://www.journalduhacker.net/t/linux.rss</a> pour suivre cette marque par RSS</li><li>Vous pourrez y faire des <a href=\"/search\">recherches</a></li></ul>En tant qu'<strong>utilisateur inscrit</strong>, vous pourrez :<ul><li>Participer aux <a href=\"/comments\" >commentaires</a></li><li>Voter pour faire remonter en haut de la page d'<a href=\"/\">accueil</a> les articles que vous appréciez</li><li><a href=\"/stories/new\" >Soumettre des articles</a> (vidéos et podcasts compris)</li><li><a href=\"/filters\">Filtrer</a> selon les marques qui vous intéressent pour afficher uniquement certaines marques sur la page d'<a href=\"/\" >accueil</a></li></ul>Le Journal du hacker est un outil simple de veille pour la sphère professionnelle, une fenêtre vers le monde du Libre, du Hacking, de l'Open source dans la sphère privée, une bibliothèque des meilleurs articles en langue française grâce à la <a href=\"/search\">fonction de recherche</a>. Il est animé par nos <a href=\"/u\" >contributeurs</a> bénévoles qui sont impliqués dans la communauté.<br /></div><h2>Les données publiques du Journal du hacker</h2><div class=\"box wide\">Un dump de la base de données du Journal du hacker est mis à disposition de la communauté afin qu'elle puisse réutiliser les informations présentes sur le Jdh. Ce dump est généré chaque jour à 1h du matin et purgé des informations confidentielles (notamment des adresses mails et mots de passe), il est téléchargeable ici : <a href=\"/assets/database/journalduhacker.sql.tar.gz\">journalduhacker.sql.tar.gz</a><br /></div><h2>Informations</h2><div class=\"box wide\">L'outil est entièrement traduit en français et basé sur le projet <a href=\"https://github.com/jcs/lobsters\">lobste.rs</a> dont vous trouverez la licence <a href=\"https://github.com/jcs/lobsters/blob/master/LICENSE\" >ici</a>.<br />Adresse de contact : <a href =\"mailto:contact@journalduhacker.net\">contact@journalduhacker.net</a>" <<
        "</div>", :layout => "application"
    end
  end

  def chat
    begin
      @title = I18n.t 'controllers.home_controller.chattitle'
      render :action => "chat"
    rescue
      render :text => "<div class=\"box wide\">" <<
        "Keep it on-site" <<
        "</div>", :layout => "application"
    end
  end

  def privacy
    begin
      @title = I18n.t 'controllers.home_controller.privacytitle'
      render :action => "privacy"
    rescue
      render :text => "<div class=\"box wide\">" <<
        "Toutes les actions sur le site sont publiques à l'exception des messages privés entre utilisateurs. Les actions de modération peuvent être consultées via le <a href=\"/moderations\">Journal de modération</a>.<br/><a rel=\"license\" href=\"http://creativecommons.org/licenses/by/4.0/\"><img alt=\"Licence Creative Commons\" style=\"border-width:0\" src=\"https://i.creativecommons.org/l/by/4.0/88x31.png\" /></a><br /><span xmlns:dct=\"http://purl.org/dc/terms/\" property=\"dct:title\">Le Journal du hacker</span> est mis à disposition selon les termes de la <a rel=\"license\" href=\"http://creativecommons.org/licenses/by/4.0/\">licence Creative Commons Attribution 4.0 International</a>." <<
        "</div>", :layout => "application"
    end
  end

  def hidden
    @stories, @show_more = get_from_cache(hidden: true) {
      paginate stories.hidden
    }

    @heading = @title = I18n.t 'controllers.home_controller.hiddenstoriestitle'
    @cur_url = "/hidden"

    render :action => "index"
  end

  def index
    @stories, @show_more = get_from_cache(hottest: true) {
      paginate stories.hottest
    }

    @rss_link ||= { :title => "RSS 2.0",
      :href => "/rss#{@user ? "?token=#{@user.rss_token}" : ""}" }
    @comments_rss_link ||= { :title => "Comments - RSS 2.0",
      :href => "/comments.rss#{@user ? "?token=#{@user.rss_token}" : ""}" }

    @heading = @title = ""
    @cur_url = "/"

    respond_to do |format|
      format.html { render :action => "index" }
      format.rss {
        if @user && params[:token].present?
          @title = "Private feed for #{@user.username}"
        end

        render :action => "rss", :layout => false
      }
      format.json { render :json => @stories }
    end
  end

  def newest
    @stories, @show_more = get_from_cache(newest: true) {
      paginate stories.newest
    }

    @heading = @title = I18n.t 'controllers.home_controller.neweststoriestitle'
    @cur_url = "/newest"

    @rss_link = { :title => "RSS 2.0 - Newest Items",
      :href => "/newest.rss#{@user ? "?token=#{@user.rss_token}" : ""}" }

    respond_to do |format|
      format.html { render :action => "index" }
      format.rss {
        if @user && params[:token].present?
          @title += " - Private feed for #{@user.username}"
        end

        render :action => "rss", :layout => false
      }
      format.json { render :json => @stories }
    end
  end

  def newest_by_user
    by_user = User.where(:username => params[:user]).first!

    @stories, @show_more = get_from_cache(by_user: by_user) {
      paginate stories.newest_by_user(by_user)
    }

    @heading = @title = "Newest Stories by #{by_user.username}"
    @cur_url = "/newest/#{by_user.username}"

    @newest = true
    @for_user = by_user.username

    respond_to do |format|
      format.html { render :action => "index" }
      format.rss {
        render :action => "rss", :layout => false
      }
      format.json { render :json => @stories }
    end
  end

  def recent
    @stories, @show_more = get_from_cache(recent: true) {
      scope = if page == 1
        stories.recent
      else
        stories.newest
      end
      paginate scope
    }

    @heading = @title = I18n.t 'controllers.home_controller.recenttitle'
    @cur_url = "/recent"

    # our content changes every page load, so point at /newest.rss to be stable
    @rss_link = { :title => "RSS 2.0 - Newest Items",
      :href => "/newest.rss#{@user ? "?token=#{@user.rss_token}" : ""}" }

    render :action => "index"
  end

  def tagged
    @tag = Tag.where(:tag => params[:tag]).first!

    @stories, @show_more = get_from_cache(tag: @tag) {
      paginate stories.tagged(@tag)
    }

    @heading = @title = @tag.description.blank?? @tag.tag : @tag.description
    @cur_url = tag_url(@tag.tag)

    @rss_link = { :title => "RSS 2.0 - Tagged #{@tag.tag} (#{@tag.description})",
      :href => "/t/#{@tag.tag}.rss" }

    respond_to do |format|
      format.html { render :action => "index" }
      format.rss { render :action => "rss", :layout => false }
      format.json { render :json => @stories }
    end
  end

  TOP_INTVS = { "d" => "Day", "w" => "Week", "m" => "Month", "y" => "Year" }
  def top
    @cur_url = "/top"
    length = { :dur => 1, :intv => "Week" }

    if m = params[:length].to_s.match(/\A(\d+)([#{TOP_INTVS.keys.join}])\z/)
      length[:dur] = m[1].to_i
      length[:intv] = TOP_INTVS[m[2]]

      @cur_url << "/#{params[:length]}"
    end

    @stories, @show_more = get_from_cache(top: true, length: length) {
      paginate stories.top(length)
    }

    if length[:dur] > 1
      @heading = @title = "Top Stories of the Past #{length[:dur]} " <<
        length[:intv] << "s"
    else
      @heading = @title = "Top Stories of the Past " << length[:intv]
    end

    render :action => "index"
  end

  def upvoted
    @stories, @show_more = get_from_cache(upvoted: true, user: @user) {
      paginate @user.upvoted_stories.order('votes.id DESC')
    }

    @heading = @title = "Your Upvoted Stories"
    @cur_url = "/upvoted"

    @rss_link = { :title => "RSS 2.0 - Your Upvoted Stories",
      :href => "/upvoted.rss#{(@user ? "?token=#{@user.rss_token}" : "")}" }

    respond_to do |format|
      format.html { render :action => "index" }
      format.rss {
        if @user && params[:token].present?
          @title += " - Private feed for #{@user.username}"
        end

        render :action => "rss", :layout => false
      }
      format.json { render :json => @stories }
    end
  end

private
  def filtered_tag_ids
    if @user
      @user.tag_filters.map{|tf| tf.tag_id }
    else
      tags_filtered_by_cookie.map{|t| t.id }
    end
  end

  def stories
    StoryRepository.new(@user, exclude_tags: filtered_tag_ids)
  end

  def page
    p = params[:page].to_i
    if p == 0
      p = 1
    elsif p < 0 || p > (2 ** 32)
      raise ActionController::RoutingError.new("page out of bounds")
    end
    p
  end

  def paginate(scope)
    StoriesPaginator.new(scope, page, @user).get
  end

  def get_from_cache(opts={}, &block)
    if Rails.env.development? || @user || tags_filtered_by_cookie.any?
      yield
    else
      key = opts.merge(page: page).sort.map{|k,v| "#{k}=#{v.to_param}"
        }.join(" ")
      Rails.cache.fetch("stories #{key}", :expires_in => 45, &block)
    end
  end
end
