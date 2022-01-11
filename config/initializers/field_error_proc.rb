# https://stackoverflow.com/questions/12252286/how-to-change-the-default-rails-error-div-field-with-errors
ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
  # add class is-danger
  if html_tag.include?('class="')
    html_tag.sub(/(class="[^"]+)"/, '\1 is-danger"').html_safe
  else
    i = html_tag.index(' ')
    %Q|#{html_tag[0..(i-1)]} class="is-danger"#{html_tag[i..-1]}|.html_safe
  end
end
