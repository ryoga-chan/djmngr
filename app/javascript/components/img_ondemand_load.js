$.fn.load_ondemand_images = function(options = {}) {
  var images = this.filter('img[data-url]');
  
  if (images.length == 0)
    images = this.find('img[data-url]');
  
  // populate 'src' attribute
  images.
    filter(':not(.ondemand-loaded)').addClass('ondemand-loaded').
    each(function() {
      var img = $(this);
      img.attr('src', img.data('url'));
    });
  
  if (options.freezeframe)
    images.freeze_frame();
  
  return this;
};//$.fn.load_ondemand_images
