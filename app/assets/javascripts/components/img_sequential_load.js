(function ($) { $(function () {
// -----------------------------------------------------------------------------
// load the next image
$.__sequential_image_loading = function (ev_type, caller) {
  //console.log({f: 'img_sequential_load', type: ev_type, caller: caller });
  
  var img = $('img.async_load:not(.loaded):first');
  
  if (img.length == 1)
    img.
      addClass('loaded').
      attr('decoding', 'async').
      attr('onload' , "jQuery.__sequential_image_loading('ok' , this)").
      attr('onerror', "jQuery.__sequential_image_loading('err', this)").
      attr('src', img.data('url'));
};//__sequential_image_loading

$.__sequential_image_loading('init');
// -----------------------------------------------------------------------------
}); })(jQuery);
