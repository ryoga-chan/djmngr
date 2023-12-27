module CoreExt::Hash::Utils
  def sort_by_value(reverse: false)
    reverse ?
      sort{|a,b| b[1] <=> a[1]} :
      sort{|a,b| a[1] <=> b[1]}
  end # sort_by_value
  
  def sort_by_key(reverse: false)
    reverse ?
      sort{|a,b| b[0] <=> a[0]} :
      sort{|a,b| a[0] <=> b[0]}
  end # sort_by_key
end

Hash.send :include, CoreExt::Hash::Utils
