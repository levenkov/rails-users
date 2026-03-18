require 'mini_magick'

class AvatarProcessor
  PROCESSED_SIZE = User::AVATAR_PROCESSED_SIZE

  def initialize(file)
    @file = file
  end

  def process
    image = MiniMagick::Image.new(file_path)
    image.resize "#{PROCESSED_SIZE}x#{PROCESSED_SIZE}^"
    image.gravity 'center'
    image.extent "#{PROCESSED_SIZE}x#{PROCESSED_SIZE}"
    image.format 'jpg'
    image.quality 85

    {
      io: File.open(image.path),
      filename: 'avatar.jpg',
      content_type: 'image/jpeg'
    }
  end

  private

  def file_path
    case @file
    when ActionDispatch::Http::UploadedFile
      @file.tempfile.path
    when Hash
      @file[:io].respond_to?(:path) ? @file[:io].path : nil
    else
      @file.path if @file.respond_to?(:path)
    end
  end
end
