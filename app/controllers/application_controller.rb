class ApplicationController < ActionController::Base
  layout -> { return 'ereader' if request.format.to_sym == :ereader }
  
  def default_url_options
    return { format: :ereader } if request.format.to_sym == :ereader
    {}
  end # default_url_options
  
  def html_redirect_to(url_or_params, delay: 0)
    render html: <<~HTML.html_safe
      <!DOCTYPE html><html><head>
      <meta http-equiv="Refresh" content="#{delay}; url='#{url_or_params}'" />
      </head><body>redirecting...</body></html>
    HTML
  end # html_redirect_to
end
