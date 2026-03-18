# Monkey patch ActiveStorage S3 service to replace internal MinIO URLs with public URLs
if Rails.env.production?
  require 'active_storage/service/s3_service'

  module ActiveStorageMinioUrlPatch
    def url(key, **options)
      original_url = super

      public_url = ENV['MINIO_PUBLIC_URL']

      return original_url unless public_url.present?

      original_uri = URI.parse(original_url)
      public_uri = URI.parse(public_url)

      original_uri.scheme = public_uri.scheme
      original_uri.host = public_uri.host
      original_uri.port = public_uri.port

      if public_uri.path && public_uri.path != '/'
        original_uri.path = public_uri.path + original_uri.path
      end

      original_uri.to_s
    end
  end

  Rails.application.config.after_initialize do
    if defined?(ActiveStorage::Service::S3Service)
      ActiveStorage::Service::S3Service.prepend(ActiveStorageMinioUrlPatch)
    end
  end
end
