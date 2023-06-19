//= require ./libs/jquery

(function($){
  // sequentially load the next image
  window.load_next_image = function (ev_type, caller) {
    var img = $('img.async_load').filter(':not(.loaded)').first();
    
    if (img.length == 1)
      img.addClass('loaded').attr('src', img.data('url'));
  }//load_next_image

  $(function () {
    // sequential image loading
    $('img.async_load').
      attr('decoding', 'async').
      attr('onload' , "load_next_image('ok' , this)").
      attr('onerror', "load_next_image('err', this)");
    load_next_image('init');
  });
})(jQuery)
