// apply Freezeframe to the context items
(function($){
// -----------------------------------------------------------------------------
$.fn.freeze_frame = function() {
  return this.
    filter(':not(.frozenframe)').addClass('frozenframe').
    each(function() { new Freezeframe(this); });
};//$.fn.freeze_frame
// -----------------------------------------------------------------------------
})(jQuery);
