module WebpackHelper
  def webpack_dev_server_url(entry)
    host = request.host
    "http://#{host}:3035/#{entry}.js"
  end

  def webpack_javascript_tag(entry, **options)
    if Rails.env.development? && webpack_dev_server_running?
      javascript_include_tag(webpack_dev_server_url(entry), **options)
    else
      javascript_include_tag(entry, **options)
    end
  end

  private

  def webpack_dev_server_running?
    return @_wds_running if defined?(@_wds_running)
    @_wds_running = begin
      TCPSocket.new("localhost", 3035).close
      true
    rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
      false
    end
  end
end
