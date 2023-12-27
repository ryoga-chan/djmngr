module CoreExt::Array::Utils
  # select 3 sets of `chunk_size` images (start/middle/end)
  def pages_preview(chunk_size:)
    if size > (chunk_size*3)
      gap = (size - chunk_size*3)/2 # number of images for a single gap
      pages = []
      pages.concat self[0...chunk_size]
      pages.concat self[gap+chunk_size, chunk_size]
      pages.concat self[(-chunk_size)..-1]
    else
      self
    end
  end # pages_preview
  
  def sort_by_method(method, params = [], reverse: false)
    params = [params] unless params.is_a?(::Array)
    
    reverse ?
      sort{|a,b| b.send(method, *params) <=> a.send(method, *params) } :
      sort{|a,b| a.send(method, *params) <=> b.send(method, *params) }
  end # sort_by_method
end

Array.send :include, CoreExt::Array::Utils
