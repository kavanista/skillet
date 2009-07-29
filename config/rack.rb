class RequireSSL < Struct.new(:app)
  def call(env)
    if env['HTTPS'] == 'on' || env['HTTP_X_FORWARDED_PROTO'] == 'https'
      app.call(env)
    else
      # I'd rather not redirect; we'll be receiving non-GET requests as well.
      [ 400, {}, 'SSL is required.' ]
    end
  end
end

# Useful for our overridden version of the chef::client config file.
class CaptureHTTPHost < Struct.new(:app)
  def call(env)
    ENV['HTTP_HOST'] ||= env['HTTP_HOST']
    app.call(env)
  end
end

unless Merb.environment == 'development'
  use RequireSSL
  use Rack::Auth::Basic do |access_token, _|
    access_token == ENV['APP_ACCESS_TOKEN']
  end
end

use CaptureHTTPHost
use Merb::Rack::Static, ChefServerSlice.dir_for(:public)
run Merb::Rack::Application.new
