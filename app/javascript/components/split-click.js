console.info('LOADING components/split-click.js');

// Fire a custom click event on each half of an element that can be splitted in
// four ways: -, |, /, \.
// 
// HTML
//   <tag data-split-mode="-">...</tag>
// 
// JS
//   $('selector').split_click({
//     mode: '-', // -, |, \, /
//     area1: function (element, event) {},
//     area2: function (element, event) {}
//   });
$.fn.split_click = function (opts) {
  opts = $.extend({mode: '-'}, opts);
  
  this.click(function (ev) {
    var el = $(this);
    
    var is_area1 = false;
    // ev.offsetX      / ev.offsetY         => element relative coordinates
    // $(this).width() / $(this).height()   => element size
    var y_ratio = el.height() / el.width();
    switch (opts.mode || el.data('split-mode')) {
      case '\\': is_area1 = ev.offsetX > (ev.offsetY / y_ratio); break;
      case  '/': is_area1 = ev.offsetX > (el.width() - ev.offsetY / y_ratio); break;
      case  '|': is_area1 = ev.offsetX > el.width() /2; break;
      case  '-': is_area1 = ev.offsetY < el.height()/2; break;
    }//switch
    
    if (is_area1) {
      if (typeof opts.area1 == 'function') opts.area1(el, ev);
    } else
      if (typeof opts.area2 == 'function') opts.area2(el, ev);
  });
  
  return this;
};// $.fn.split_click
