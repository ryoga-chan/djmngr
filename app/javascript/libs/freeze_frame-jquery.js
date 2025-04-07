// `freeze_frame` jQuery plugin -- https://github.com/ctrl-freaks/freezeframe.js
import Freezeframe from 'freezeframe';
window.Freezeframe ||= Freezeframe;

if (!Freezeframe) { throw new Error('Freezeframe is required!'); }

$.fn.freeze_frame = function() {
  return this.
    // run only when the image is loaded --  https://stackoverflow.com/questions/3877027/jquery-callback-on-image-load-even-when-the-image-is-cached/3877079#3877079
    one('load', function() {
      $(this).addClass('frozenframe');
      new Freezeframe(this);
    }).each(function() {
      if (this.complete && !$(this).hasClass('frozenframe'))
        $(this).trigger('load');
    });
};//$.fn.freeze_frame
