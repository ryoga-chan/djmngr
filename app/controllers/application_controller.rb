class ApplicationController < ActionController::Base
  layout -> { return 'ereader' if request.format.ereader? }
  
  def default_url_options
    opts = {}
    opts.merge! format: :ereader if request.format.ereader?
    opts
  end # default_url_options
  
  def html_redirect_to(url_or_params, delay: 0)
    url = url_for url_or_params
    
    render html: <<~HTML.html_safe
      <!DOCTYPE html><html><head>
      <meta http-equiv="Refresh" content="#{delay}; url='#{url}'" />
      </head><body>redirecting to <a href="#{url}">#{url}</a> ...</body></html>
    HTML
  end # html_redirect_to
  
  
  private
  
  
  # used with before_action to set detail level (thumbs or table)
  def set_doujin_list_detail
    session[:dj_index_detail] = params[:detail] if %w{ thumbs table }.include?(params[:detail])
    session[:dj_index_detail] ||= 'table'
  end # set_doujin_list_detail
end
