class RecitationStyle < QuranApiRecord
  include NameTranslateable

  def name
    self.style
  end
end
