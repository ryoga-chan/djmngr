// `sortable` jQuery plugin -- https://github.com/SortableJS/jquery-sortablejs | https://github.com/SortableJS/Sortable
console.info('LOADING libs/sortable-jquery.js');

import Sortable from 'sortablejs';
window.Sortable ||= Sortable;

if (!Sortable) { throw new Error('SortableJS is required!'); }

$.fn.sortable = function (options) {
  var retVal, args = arguments;

  this.each(function () {
    var el = $(this),
      sortable = el.data('sortable');

    if (!sortable && (options instanceof Object || !options)) {
      sortable = new Sortable(this, options);
      el.data('sortable', sortable);
    } else if (sortable) {
      if (options === 'destroy') {
        sortable.destroy();
        el.removeData('sortable');
      } else if (options === 'widget') {
        retVal = sortable;
      } else if (typeof sortable[options] === 'function') {
        retVal = sortable[options].apply(sortable, [].slice.call(args, 1));
      } else if (options in sortable.options) {
        retVal = sortable.option.apply(sortable, args);
      }
    }
  });

  return (retVal === void 0) ? this : retVal;
};//$.fn.sortable
