Rails.application.configure do
  config.hosts << /.+.lan/
  config.hosts << /.+.vpn/
end if Rails.env.development?
