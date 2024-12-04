// `freeze_frame` jQuery plugin -- https://github.com/ctrl-freaks/freezeframe.js
import Freezeframe from 'freezeframe';
window.Freezeframe ||= Freezeframe;

if (!Freezeframe) { throw new Error('Freezeframe is required!'); }

$.fn.freeze_frame = function() {
  return this.
    filter(':not(.frozenframe)').addClass('frozenframe').
    each(function() { new Freezeframe(this); });
};//$.fn.freeze_frame
