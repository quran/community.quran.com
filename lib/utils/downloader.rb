module Utils
  class Downloader
    def self.download(url, filename)
      require 'mechanize'
  
      agent = Mechanize.new
      agent.pluggable_parser.default = Mechanize::Download
      agent.get(url).save(filename)
    end
  end
end
