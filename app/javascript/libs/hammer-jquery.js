// `hammer` jQuery plugin -- https://github.com/hammerjs/jquery.hammer.js | https://github.com/hammerjs/hammer.js
console.info('LOADING libs/hammer-jquery.js');

if (!Hammer) { throw new Error('Hammer is required!'); }

// extend the emit method to also trigger jQuery events
Hammer.Manager.prototype.emit = (function (originalEmit) {
  return function(type, data) {
    originalEmit.call(this, type, data);
    $(this.element).trigger({ type: type, gesture: data });
  };
})(Hammer.Manager.prototype.emit);

Hammer.jquery_hammerify = function (el, options) {
  if(!el.data("hammer"))
    el.data("hammer", new Hammer(el.get(0), options));
}//Hammer.jquery_hammerify

$.fn.hammer = function (options) {
  return this.each(function() { Hammer.jquery_hammerify($(this), options); });
};//$.fn.hammer
