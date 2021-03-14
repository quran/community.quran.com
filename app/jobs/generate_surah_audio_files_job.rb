class GenerateSurahAudioFilesJob < ApplicationJob
  queue_as :default

  def perform(recitation_id:)
    require 'wahwah'
    recitation = Audio::Recitation.find(recitation_id)
    FileUtils.mkdir_p("tmp/audio_meta_data")

    1.upto(114).each do |chapter_number|
      create_file(chapter_number: chapter_number, recitation: recitation)
    end

    clean_up
  end

  protected

  def create_file(chapter_number:, recitation:)
    meta_file = fetch_meta_data(chapter_number: chapter_number, recitation: recitation)

    #ID3Tag.read(File.open(meta_file, 'rb'))
    # wahwah would give more info
    meta = WahWah.open(meta_file)

    audio_file = recitation
                   .chapter_audio_files
                   .where(chapter_id: chapter_number)
                   .first_or_create

    audio_file.attributes = {
      chapter_id: chapter_number,
      bit_rate: meta.bitrate,
      download_count: 0,
      stream_count: 0,
      duration: meta.duration,
      file_name: "#{chapter_number.to_s.rjust 3, '0'}.#{recitation.file_formats}",
      file_size: meta.file_size,
      format: recitation.file_formats,
      mime_type: '',
      metadata: {
        album: meta.album.presence || "Quran",
        genre: meta.genre.presence || "Quran",
        title: meta.title,
        track: "#{meta.track}/#{meta.track_total}",
        artist: meta.artist,
        year: meta.year,
        sample_rate: meta.sample_rate,
        format_long_name: MIME::Types.type_for(meta_file).first.content_type
      } }

    audio_file.save
  end

  def fetch_meta_data(chapter_number:, recitation:)
    url = "https://download.quranicaudio.com/quran/#{recitation.relative_path}#{chapter_number.to_s.rjust 3, '0'}.#{recitation.file_formats}"
    fetch_bytes(url, 2.megabyte)
  end

  def fetch_bytes(url, size)
    uri = URI(url)
    Net::HTTP.version_1_2 # make sure we use higher HTTP protocol version than 1.0

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    body = http.get(url, { 'Range' => "bytes=0-#{size}" }).body

    tmp_file_name = "audio-#{Time.now.to_i}.mp3"
    File.open("tmp/audio_meta_data/#{tmp_file_name}", "wb") do |file|
      file << body
    end

    "tmp/audio_meta_data/#{tmp_file_name}"
  end

  def clean_up
    FileUtils.remove_dir("tmp/audio_meta_data")
  end
end
