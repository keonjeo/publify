# coding: utf-8
class String
  # Returns a-string-with-dashes when passed 'a string with dashes'.
  # All special chars are stripped in the process
  def to_url
    return if self.nil?

    s = self.downcase.tr("\"'", '')
    # Inject correct version-dependent regex using string interpolations
    # since the 1.9 version is invalid for 1.8.
    s = s.gsub(/#{RUBY_VERSION < "1.9" ? '\W' : '\P{Word}'}/, ' ')
    s.strip.tr_s(' ', '-').tr(' ', '-').sub(/^$/, "-")
  end

  # A quick and dirty fix to add 'nofollow' to any urls in a string.
  # FIXME: Decidedly unsafe, but will have to do for now.
  def nofollowify
    return self if Blog.default.dofollowify
    self.gsub(/<a(.*?)>/i, '<a\1 rel="nofollow">')
  end

  # I pass settings as a parametre to avoid calling Blog.default (and another
  #  database call) everytime I want to use to_title
  # Not sure on this one though.
  def to_title(item, settings, params)
    s = self
    
    # Tags for params
    s = s.gsub('%date%', parse_date(s, params)) if s =~ /(%date%)/
    s = s.gsub('%search%', params[:q]) if params[:q]
    s = s.gsub('%page%', parse_page(s, params)) if s=~ /(%page%)/
    
    # Tags for settings
    s = s.gsub('%blog_name%', settings.blog_name) 
    s = s.gsub('%blog_subtitle%', settings.blog_subtitle)
    s = s.gsub('%meta_keywords%', settings.meta_keywords)
    
    # Tags for item
    s = s.gsub('%title%', item.title) if s =~ /(%title)/ and item.respond_to? :title
    s = s.gsub('%excerpt%', (item.body || '').strip_html.slice(0, 160)) if s =~ /(%excerpt%)/ and item.respond_to? :body
    s = s.gsub('%description%', item.description) if s =~ /(%description%)/ and item.respond_to? :description
    s = s.gsub('%name%', item.name) if s =~ /(%name%)/ and item.respond_to? :name
    s = s.gsub('%author%', item.name) if s =~ /(%author%)/ and item.respond_to? :name
    
    if s =~ /(%categories%)/ and item.respond_to? :categories
      s = s.gsub('%categories%', article.categories.map { |c| c.name }.join(", "))
    end

    if s =~ /(%tags%)/ and item.respond_to? :tags
      s = s.gsub('%tags%', article.tags.map { |t| t.display_name }.join(", "))
    end

    # Other
    s = s.gsub('%currentdate%', Time.now.strftime(settings.date_format))
    s = s.gsub('%currenttime%', Time.now.strftime(settings.time_format))
    s = s.gsub('%currentmonth%', Time.now.strftime("%B"))
    s = s.gsub('%currentyear%', Time.now.year.to_s)
    return s
  end
  
  # Strips any html markup from a string
  TYPO_TAG_KEY = TYPO_ATTRIBUTE_KEY = /[\w:_-]+/
  TYPO_ATTRIBUTE_VALUE = /(?:[A-Za-z0-9]+|(?:'[^']*?'|"[^"]*?"))/
  TYPO_ATTRIBUTE = /(?:#{TYPO_ATTRIBUTE_KEY}(?:\s*=\s*#{TYPO_ATTRIBUTE_VALUE})?)/
  TYPO_ATTRIBUTES = /(?:#{TYPO_ATTRIBUTE}(?:\s+#{TYPO_ATTRIBUTE})*)/
  TAG = %r{<[!/?\[]?(?:#{TYPO_TAG_KEY}|--)(?:\s+#{TYPO_ATTRIBUTES})?\s*(?:[!/?\]]+|--)?>}
  def strip_html
    self.gsub(TAG, '').gsub(/\s+/, ' ').strip
  end

  private
  def parse_date(string, params)
    return '' unless params[:year]
    
    format = ''
    format << '%A %d ' if params[:day]
    format << '%B ' if params[:month]
    format << '%Y' if params[:year]
    
    string.gsub('%date%', Time.mktime(*params.values_at(:year, :month, :day)).strftime(format))
  end
  
  def parse_page(string, params)
    return '' unless params[:page]
    "#{_('page')} #{params[:page]}"
  end
  
end
