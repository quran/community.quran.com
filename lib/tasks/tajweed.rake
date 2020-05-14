namespace :tajweed do
  task parse: :environment do
    require "#{Rails.root}/lib/utils/tajweed_text.rb"
    require 'open-uri'

    Verse.find_each do |v|
      next if v.text_uthmani_tajweed.present?

      url = "http://api.alquran.cloud/ayah/#{v.verse_key}/quran-tajweed"
      text = JSON.parse(URI.open(url).read)['data']['text']

      parser =TajweedText.new text

      tajweed = parser.parse_buckwalter_tajweed(text)

      v.update_column :text_uthmani_tajweed, tajweed
    end
  end
end
