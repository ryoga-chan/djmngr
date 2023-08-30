// adaption of https://github.com/hammerjs/jquery.hammer.js/raw/master/jquery.hammer.js
(function($){
// -----------------------------------------------------------------------------
function hammerify (el, options) {
  var $el = $(el);
  if(!$el.data("hammer"))
    $el.data("hammer", new Hammer($el[0], options));
}//hammerify

$.fn.hammer = function(options) {
  return this.each(function() { hammerify(this, options); });
};//$.fn.hammer

// extend the emit method to also trigger jQuery events
Hammer.Manager.prototype.emit = (function (originalEmit) {
  return function(type, data) {
    originalEmit.call(this, type, data);
    $(this.element).trigger({ type: type, gesture: data });
  };
})(Hammer.Manager.prototype.emit);
// -----------------------------------------------------------------------------
})(jQuery);
