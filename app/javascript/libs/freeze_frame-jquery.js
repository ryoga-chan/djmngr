console.info('imported: libs/freeze_frame-jquery');

import 'libs/jquery'; // sets window.{jQuery, $}

// `freeze_frame` jQuery plugin -- https://github.com/ctrl-freaks/freezeframe.js
import Freezeframe from 'freezeframe';
window.Freezeframe ||= Freezeframe;

$.fn.freeze_frame = function() {
  return this.filter(':not(.frozenframe)').
    // run only when the image is loaded --  https://stackoverflow.com/questions/3877027/jquery-callback-on-image-load-even-when-the-image-is-cached/3877079#3877079
    one('load', function() {
      $(this).addClass('frozenframe');
      new Freezeframe(this);
    }).each(function() {
      if (this.complete && !$(this).hasClass('frozenframe'))
        $(this).trigger('load');
    });
};//$.fn.freeze_frame
