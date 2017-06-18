class Story < ActiveRecord::Base
  belongs_to :user
  belongs_to :merged_into_story,
    :class_name => "Story",
    :foreign_key => "merged_story_id"
  has_many :merged_stories,
    :class_name => "Story",
    :foreign_key => "merged_story_id"
  has_many :taggings,
    :autosave => true
  has_many :suggested_taggings
  has_many :suggested_titles
  has_many :comments,
    :inverse_of => :story
  has_many :tags, :through => :taggings
  has_many :votes, -> { where(:comment_id => nil) }
  has_many :voters, -> { where('votes.comment_id' => nil) },
    :through => :votes,
    :source => :user

  scope :unmerged, -> { where(:merged_story_id => nil) }

  validates_length_of :title, :in => 3..150
  validates_length_of :description, :maximum => (64 * 1024)
  validates_length_of :url, :maximum => 250, :allow_nil => true
  validates_presence_of :user_id

  validates_each :merged_story_id do |record,attr,value|
    if value.to_i == record.id
      record.errors.add(:merge_story_short_id, "id cannot be itself.")
    end
  end

  DOWNVOTABLE_DAYS = 14

  # the lowest a score can go
  DOWNVOTABLE_MIN_SCORE = -5

  # after this many minutes old, a story cannot be edited
  MAX_EDIT_MINS = (60 * 6)

  # days a story is considered recent, for resubmitting
  RECENT_DAYS = 30

  # users needed to make similar suggestions go live
  SUGGESTION_QUORUM = 2

  # let a hot story linger for this many seconds
  HOTNESS_WINDOW = 60 * 60 * 22

  attr_accessor :vote, :already_posted_story, :previewing, :seen_previous,
    :is_hidden_by_cur_user
  attr_accessor :editor, :moderation_reason, :merge_story_short_id,
    :editing_from_suggestions
  attr_accessor :fetching_ip
  attr_writer :fetched_content

  before_validation :assign_short_id_and_upvote,
    :on => :create
  before_create :assign_initial_hotness
  before_save :log_moderation
  before_save :fix_bogus_chars
  after_create :mark_submitter, :record_initial_upvote
  after_save :update_merged_into_story_comments, :recalculate_hotness!

  validate do
    if self.url.present?
      # URI.parse is not very lenient, so we can't use it

      if self.url.match(/\Ahttps?:\/\/([^\.]+\.)+[a-z]+(\/|\z)/i)
        if self.new_record? && (s = Story.find_similar_by_url(self.url))
          self.already_posted_story = s
          if s.is_recent?
            errors.add(:url, "has already been submitted within the past " <<
              "#{RECENT_DAYS} days")
          end
        end
      else
        errors.add(:url, "is not valid")
      end
    elsif self.description.to_s.strip == ""
      errors.add(:description, "must contain text if no URL posted")
    end

    if !errors.any? && self.url.blank?
      self.user_is_author = true
    end

    check_tags
  end

  def self.find_similar_by_url(url)
    urls = [ url.to_s ]
    urls2 = [ url.to_s ]

    # https
    urls.each do |u|
      urls2.push u.gsub(/^http:\/\//i, "https://")
      urls2.push u.gsub(/^https:\/\//i, "http://")
    end
    urls = urls2.clone

    # trailing slash
    urls.each do |u|
      urls2.push u.gsub(/\/+\z/, "")
      urls2.push (u + "/")
    end
    urls = urls2.clone

    # www prefix
    urls.each do |u|
      urls2.push u.gsub(/^(https?:\/\/)www\d*\./i) {|_| $1 }
      urls2.push u.gsub(/^(https?:\/\/)/i) {|_| "#{$1}www." }
    end
    urls = urls2.clone

    # if a previous submission was moderated, return it to block it from being
    # submitted again
    if s = Story.where(:url => urls).
    where("is_expired = ? OR is_moderated = ?", false, true).
    order("id DESC").first
      return s
    end

    false
  end

  def self.recalculate_all_hotnesses!
    # do the front page first, since find_each can't take an order
    Story.order("id DESC").limit(100).each do |s|
      s.recalculate_hotness!
    end
    Story.find_each do |s|
      s.recalculate_hotness!
    end
    true
  end

  def self.score_sql
    "(CAST(upvotes AS #{votes_cast_type}) - " <<
      "CAST(downvotes AS #{votes_cast_type}))"
  end

  def self.votes_cast_type
    Story.connection.adapter_name.match(/mysql/i) ? "signed" : "integer"
  end

  def archive_url
    "https://archive.is/#{CGI.escape(self.url)}"
  end

  def as_json(options = {})
    h = [
      :short_id,
      :short_id_url,
      :created_at,
      :title,
      :url,
      :score,
      :upvotes,
      :downvotes,
      { :comment_count => :comments_count },
      { :description => :markeddown_description },
      :comments_url,
      { :submitter_user => :user },
      { :tags => self.tags.map{|t| t.tag }.sort },
    ]

    if options && options[:with_comments]
      h.push({ :comments => options[:with_comments] })
    end

    js = {}
    h.each do |k|
      if k.is_a?(Symbol)
        js[k] = self.send(k)
      elsif k.is_a?(Hash)
        if k.values.first.is_a?(Symbol)
          js[k.keys.first] = self.send(k.values.first)
        else
          js[k.keys.first] = k.values.first
        end
      end
    end

    js
  end

  def assign_initial_hotness
    self.hotness = self.calculated_hotness
  end

  def assign_short_id_and_upvote
    self.short_id = ShortId.new(self.class).generate
    self.upvotes = 1
  end

  def calculated_hotness
    # take each tag's hotness modifier into effect, and give a slight bump to
    # stories submitted by the author
    base = self.tags.map{|t| t.hotness_mod }.sum +
      (self.user_is_author ? 0.25 : 0.0)

    # give a story's comment votes some weight, ignoring submitter's comments
    cpoints = self.comments.
      where("user_id <> ?", self.user_id).
      select(:upvotes, :downvotes).
      map{|c|
        if base < 0
          # in stories already starting out with a bad hotness mod, only look
          # at the downvotes to find out if this tire fire needs to be put out
          c.downvotes * -0.5
        else
          c.upvotes + 1 - c.downvotes
        end
      }.
      inject(&:+).to_f * 0.5

    # mix in any stories this one cannibalized
    cpoints += self.merged_stories.map{|s| s.score }.inject(&:+).to_f

    # if a story has many comments but few votes, it's probably a bad story, so
    # cap the comment points at the number of upvotes
    if cpoints > self.upvotes
      cpoints = self.upvotes
    end

    # don't immediately kill stories at 0 by bumping up score by one
    order = Math.log([ (score + 1).abs + cpoints, 1 ].max, 10)
    if score > 0
      sign = 1
    elsif score < 0
      sign = -1
    else
      sign = 0
    end

    return -((order * sign) + base +
      ((self.created_at || Time.now).to_f / HOTNESS_WINDOW)).round(7)
  end

  def can_be_seen_by_user?(user)
    if is_gone? && !(user && (user.is_moderator? || user.id == self.user_id))
      return false
    end

    true
  end

  def can_have_suggestions_from_user?(user)
    if !user || (user.id == self.user_id) || !user.can_offer_suggestions?
      return false
    end

    if self.taggings.select{|t| t.tag && t.tag.privileged? }.any?
      return false
    end

    return true
  end

  # this has to happen just before save rather than in tags_a= because we need
  # to have a valid user_id
  def check_tags
    u = self.editor || self.user

    self.taggings.each do |t|
      if !t.tag.valid_for?(u)
        raise "#{u.username} does not have permission to use privileged " <<
          "tag #{t.tag.tag}"
      elsif t.tag.inactive? && t.new_record? && !t.marked_for_destruction?
        # stories can have inactive tags as long as they existed before
        raise "#{u.username} cannot add inactive tag #{t.tag.tag}"
      end
    end

    if !self.taggings.reject{|t| t.marked_for_destruction? || t.tag.is_media?
    }.any?
      errors.add(:base, "Must have at least one non-media (PDF, video) " <<
        "tag.  If no tags apply to your content, it probably doesn't " <<
        "belong here.")
    end
  end

  def comments_path
    "#{short_id_path}/#{self.title_as_url}"
  end

  def comments_url
    "#{short_id_url}/#{self.title_as_url}"
  end

  def description=(desc)
    self[:description] = desc.to_s.rstrip
    self.markeddown_description = self.generated_markeddown_description
  end

  def description_or_story_cache(chars = 0)
    s = if self.description.present?
      self.markeddown_description.gsub(/<[^>]*>/, "")
    else
      self.story_cache
    end

    if chars > 0
      # remove last truncated word
      s = s.to_s[0, chars].gsub(/ [^ ]*\z/, "")
    end

    HTMLEntities.new.decode(s.to_s)
  end

  def domain
    if self.url.blank?
      nil
    else
      # URI.parse is not very lenient, so we can't use it
      self.url.
        gsub(/^[^:]+:\/\//, "").        # proto
        gsub(/\/.*/, "").               # path
        gsub(/:\d+$/, "").              # possible port
        gsub(/^www\d*\.(.+\..+)/, '\1') # possible "www3." in host unless
                                        # it's the only non-TLD
    end
  end

  def domain_search_url
    "/search?q=domain:#{self.domain}&order=newest"
  end

  def fetch_story_cache!
    if self.url.present?
      self.story_cache = StoryCacher.get_story_text(self)
    end
  end

  def fix_bogus_chars
    # this is needlessly complicated to work around character encoding issues
    # that arise when doing just self.title.to_s.gsub(160.chr, "")
    self.title = self.title.to_s.split("").map{|chr|
      if chr.ord == 160
        " "
      else
        chr
      end
    }.join("")

    true
  end

  def generated_markeddown_description
    Markdowner.to_html(self.description, { :allow_images => true })
  end

  def give_upvote_or_downvote_and_recalculate_hotness!(upvote, downvote)
    self.upvotes += upvote.to_i
    self.downvotes += downvote.to_i

    Story.connection.execute("UPDATE #{Story.table_name} SET " <<
      "upvotes = COALESCE(upvotes, 0) + #{upvote.to_i}, " <<
      "downvotes = COALESCE(downvotes, 0) + #{downvote.to_i}, " <<
      "hotness = '#{self.calculated_hotness}' WHERE id = #{self.id.to_i}")
  end

  def has_suggestions?
    self.suggested_taggings.any? || self.suggested_titles.any?
  end

  def hider_count
    @hider_count ||= HiddenStory.where(:story_id => self.id).count
  end

  def html_class_for_user
    c = []
    if !self.user.is_active?
      c.push "inactive_user"
    elsif self.user.is_new?
      c.push "new_user"
    elsif self.user_is_author?
      c.push "user_is_author"
    end

    c.join("")
  end

  def is_downvotable?
    if self.created_at && self.score >= DOWNVOTABLE_MIN_SCORE
      Time.now - self.created_at <= DOWNVOTABLE_DAYS.days
    else
      false
    end
  end

  def is_editable_by_user?(user)
    if user && user.is_moderator?
      return true
    elsif user && user.id == self.user_id
      if self.is_moderated?
        return false
      else
        return (Time.now.to_i - self.created_at.to_i < (60 * MAX_EDIT_MINS))
      end
    else
      return false
    end
  end

  def is_gone?
    is_expired?
  end

  def is_hidden_by_user?(user)
    !!HiddenStory.where(:user_id => user.id, :story_id => self.id).first
  end

  def is_recent?
    self.created_at >= RECENT_DAYS.days.ago
  end

  def is_unavailable
    self.unavailable_at != nil
  end
  def is_unavailable=(what)
    self.unavailable_at = (what.to_i == 1 && !self.is_unavailable ?
      Time.now : nil)
  end

  def is_undeletable_by_user?(user)
    if user && user.is_moderator?
      return true
    elsif user && user.id == self.user_id && !self.is_moderated?
      return true
    else
      return false
    end
  end

  def log_moderation
    if self.new_record? ||
    (!self.editing_from_suggestions &&
    (!self.editor || self.editor.id == self.user_id))
      return
    end

    all_changes = self.changes.merge(self.tagging_changes)
    all_changes.delete("unavailable_at")

    if !all_changes.any?
      return
    end

    m = Moderation.new
    if self.editing_from_suggestions
      m.is_from_suggestions = true
    else
      m.moderator_user_id = self.editor.try(:id)
    end
    m.story_id = self.id

    if all_changes["is_expired"] && self.is_expired?
      m.action = "deleted story"
    elsif all_changes["is_expired"] && !self.is_expired?
      m.action = "undeleted story"
    else
      m.action = all_changes.map{|k,v|
        if k == "merged_story_id"
          if v[1]
            "merged into #{self.merged_into_story.short_id} " <<
              "(#{self.merged_into_story.title})"
          else
            "unmerged from another story"
          end
        else
          "changed #{k} from #{v[0].inspect} to #{v[1].inspect}"
        end
      }.join(", ")
    end

    m.reason = self.moderation_reason
    m.save

    self.is_moderated = true
  end

  def mailing_list_message_id
    "story.#{short_id}.#{created_at.to_i}@#{Rails.application.domain}"
  end

  def mark_submitter
    Keystore.increment_value_for("user:#{self.user_id}:stories_submitted")
  end

  def merged_comments
    # TODO: make this a normal has_many?
    Comment.where(:story_id => Story.select(:id).
      where(:merged_story_id => self.id) + [ self.id ])
  end

  def merge_story_short_id=(sid)
    self.merged_story_id = sid.present??
      Story.where(:short_id => sid).first.id : nil
  end

  def merge_story_short_id
    self.merged_story_id ? self.merged_into_story.try(:short_id) : nil
  end

  def recalculate_hotness!
    update_column :hotness, calculated_hotness
  end

  def record_initial_upvote
    Vote.vote_thusly_on_story_or_comment_for_user_because(1, self.id, nil,
      self.user_id, nil, false)
  end

  def score
    upvotes - downvotes
  end

  def short_id_path
    Rails.application.routes.url_helpers.root_path + "s/#{self.short_id}"
  end

  def short_id_url
    Rails.application.root_url + "s/#{self.short_id}"
  end

  def sorted_taggings
    self.taggings.sort_by{|t| t.tag.tag }.sort_by{|t| t.tag.is_media?? -1 : 0 }
  end

  def tagging_changes
    old_tags_a = self.taggings.reject{|tg| tg.new_record? }.map{|tg|
      tg.tag.tag }.join(" ")
    new_tags_a = self.taggings.reject{|tg| tg.marked_for_destruction?
      }.map{|tg| tg.tag.tag }.join(" ")

    if old_tags_a == new_tags_a
      {}
    else
      { "tags" => [ old_tags_a, new_tags_a ] }
    end
  end

  @_tags_a = []
  def tags_a
    @_tags_a ||= self.taggings.reject{|t| t.marked_for_destruction?
      }.map{|t| t.tag.tag }
  end

  def tags_a=(new_tag_names_a)
    self.taggings.each do |tagging|
      if !new_tag_names_a.include?(tagging.tag.tag)
        tagging.mark_for_destruction
      end
    end

    new_tag_names_a.each do |tag_name|
      if tag_name.to_s != "" && !self.tags.exists?(:tag => tag_name)
        if t = Tag.active.where(:tag => tag_name).first
          # we can't lookup whether the user is allowed to use this tag yet
          # because we aren't assured to have a user_id by now; we'll do it in
          # the validation with check_tags
          tg = self.taggings.build
          tg.tag_id = t.id
        end
      end
    end
  end

  def save_suggested_tags_a_for_user!(new_tag_names_a, user)
    st = self.suggested_taggings.where(:user_id => user.id)

    st.each do |tagging|
      if !new_tag_names_a.include?(tagging.tag.tag)
        tagging.destroy
      end
    end

    st.reload

    new_tag_names_a.each do |tag_name|
      # XXX: AR bug? st.exists?(:tag => tag_name) does not work
      if tag_name.to_s != "" && !st.map{|x| x.tag.tag }.include?(tag_name)
        if (t = Tag.active.where(:tag => tag_name).first) &&
        t.valid_for?(user)
          tg = self.suggested_taggings.build
          tg.user_id = user.id
          tg.tag_id = t.id
          tg.save!

          st.reload
        else
          next
        end
      end
    end

    # if enough users voted on the same set of replacement tags, do it
    tag_votes = {}
    self.suggested_taggings.group_by(&:user_id).each do |u,stg|
      stg.each do |st|
        tag_votes[st.tag.tag] ||= 0
        tag_votes[st.tag.tag] += 1
      end
    end

    final_tags = []
    tag_votes.each do |k,v|
      if v >= SUGGESTION_QUORUM
        final_tags.push k
      end
    end

    if final_tags.any? && (final_tags.sort != self.tags_a.sort)
      Rails.logger.info "[s#{self.id}] promoting suggested tags " <<
        "#{final_tags.inspect} instead of #{self.tags_a.inspect}"
      self.editor = nil
      self.editing_from_suggestions = true
      self.moderation_reason = "Automatically changed from user suggestions"
      self.tags_a = final_tags.sort
      if !self.save
        Rails.logger.error "[s#{self.id}] failed auto promoting: " <<
          self.errors.inspect
      end
    end
  end

  def save_suggested_title_for_user!(title, user)
    st = self.suggested_titles.where(:user_id => user.id).first
    if !st
      st = self.suggested_titles.build
      st.user_id = user.id
    end
    st.title = title
    st.save!

    # if enough users voted on the same exact title, save it
    title_votes = {}
    self.suggested_titles.each do |st|
      title_votes[st.title] ||= 0
      title_votes[st.title] += 1
    end

    title_votes.sort_by{|k,v| v }.reverse.each do |kv|
      if kv[1] >= SUGGESTION_QUORUM
        Rails.logger.info "[s#{self.id}] promoting suggested title " <<
          "#{kv[0].inspect} instead of #{self.title.inspect}"
        self.editor = nil
        self.editing_from_suggestions = true
        self.moderation_reason = "Automatically changed from user suggestions"
        self.title = kv[0]
        if !self.save
          Rails.logger.error "[s#{self.id}] failed auto promoting: " <<
            self.errors.inspect
        end

        break
      end
    end
  end

  def title=(t)
    # change unicode whitespace characters into real spaces
    self[:title] = t.strip
  end

  def title_as_url
    max_len = 35
    wl = 0
    words = []

    self.title.downcase.gsub(/[,'`\"]/, "").gsub(/[^a-z0-9]/, "_").split("_").
    reject{|z| [ "", "a", "an", "and", "but", "in", "of", "or", "that", "the",
    "to" ].include?(z) }.each do |w|
      if wl + w.length <= max_len
        words.push w
        wl += w.length
      else
        if wl == 0
          words.push w[0, max_len]
        end
        break
      end
    end

    if !words.any?
      words.push "_"
    end

    words.join("_").gsub(/_-_/, "-")
  end

  def to_param
    self.short_id
  end

  def update_availability
    if self.is_unavailable && !self.unavailable_at
      self.unavailable_at = Time.now
    elsif self.unavailable_at && !self.is_unavailable
      self.unavailable_at = nil
    end
  end

  def update_comments_count!
    comments = self.merged_comments.arrange_for_user(nil)

    # calculate count after removing deleted comments and threads
    self.update_column :comments_count,
      (self.comments_count = comments.count{|c| !c.is_gone? })

    self.recalculate_hotness!
  end

  def update_merged_into_story_comments
    if self.merged_into_story
      self.merged_into_story.update_comments_count!
    end
  end

  def url=(u)
    # strip out stupid google analytics parameters
    if u && (m = u.match(/\A([^\?]+)\?(.+)\z/))
      params = m[2].split("&")
      params.reject!{|p|
        p.match(/^utm_(source|medium|campaign|term|content)=/) }

      u = m[1] << (params.any?? "?" << params.join("&") : "")
    end

    self[:url] = u.to_s.strip
  end

  def url_is_editable_by_user?(user)
    if self.new_record?
      true
    elsif user && user.is_moderator? && self.url.present?
      true
    else
      false
    end
  end

  def url_or_comments_path
    self.url.blank? ? self.comments_path : self.url
  end

  def url_or_comments_url
    self.url.blank? ? self.comments_url : self.url
  end

  def vote_summary_for(user)
    r_counts = {}
    r_whos = {}
    Vote.where(:story_id => self.id, :comment_id => nil).where("vote != 0").each do |v|
      r_counts[v.reason.to_s] ||= 0
      r_counts[v.reason.to_s] += v.vote
      if user && user.is_moderator?
        r_whos[v.reason.to_s] ||= []
        r_whos[v.reason.to_s].push v.user.username
      end
    end

    r_counts.keys.sort.map{|k|
      if k == ""
        "+#{r_counts[k]}"
      else
        "#{r_counts[k]} " +
          (Vote::STORY_REASONS[k] || Vote::OLD_STORY_REASONS[k] || k) +
          (user && user.is_moderator?? " (#{r_whos[k].join(", ")})" : "")
      end
    }.join(", ")
  end

  def fetched_attributes
    if @fetched_attributes
      return @fetched_attributes
    end

    @fetched_attributes = {
      :url => self.url,
      :title => "",
    }

    if !@fetched_content
      begin
        s = Sponge.new
        s.timeout = 3
        @fetched_content = s.fetch(self.url, :get, nil, nil, {
          "User-agent" => "#{Rails.application.domain} for #{self.fetching_ip}"
        }, 3)
      rescue
        return @fetched_attributes
      end
    end

    parsed = Nokogiri::HTML(@fetched_content.to_s)

    # parse best title from html tags
    # try <meta property="og:title"> first, it probably won't have the site
    # name
    title = ""
    begin
      title = parsed.at_css("meta[property='og:title']").
        attributes["content"].text
    rescue
    end

    # then try <meta name="title">
    if title.to_s == ""
      begin
        title = parsed.at_css("meta[name='title']").attributes["content"].text
      rescue
      end
    end

    # then try plain old <title>
    if title.to_s == ""
      title = parsed.at_css("title").try(:text).to_s
    end

    # see if the site name is available, so we can strip it out in case it was
    # present in the fetched title
    begin
      site_name = parsed.at_css("meta[property='og:site_name']").
        attributes["content"].text

      if site_name.present? && site_name.length < title.length &&
      title[-(site_name.length), site_name.length] == site_name
        title = title[0, title.length - site_name.length]

        # remove title/site name separator
        if title.match(/ [ \-\|\u2013] $/)
          title = title[0, title.length - 3]
        end
      end
    rescue
    end

    @fetched_attributes[:title] = title

    # now get canonical version of url (though some cms software puts incorrect
    # urls here, hopefully the user will notice)
    begin
      if (cu = parsed.at_css("link[rel='canonical']").attributes["href"].
      text).present? && (ucu = URI.parse(cu)) && ucu.scheme.present? &&
      ucu.host.present?
        @fetched_attributes[:url] = cu
      end
    rescue
    end

    @fetched_attributes
  end
end
