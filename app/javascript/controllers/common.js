console.info('imported: controllers/common');

import 'libs/app-setup';

$(function () {
// -----------------------------------------------------------------------------
// toggle favorites
$('a.fav').on('click', function (ev) {
  ev.preventDefault();
  var el    = $(this),
      is_bt = el.hasClass('button');
  
  $.ajax({
    url: el.attr('href'),
    dataType: 'json',
    cache: false,
    beforeSend: function () {
      if (is_bt)
        el.addClass('is-loading');
      else
        el.data('text', el.html()).html(MyApp.p_bar);
    },//beforeSend
    success: function (resp) {
      if (resp.result != 'ok')
        alert(resp.msg || 'Server error!');
      el.toggleClass(is_bt ? 'is-warning' : 'has-text-warning', resp.favorite);
    },//success
    complete: function () {
      if (is_bt)
        el.removeClass('is-loading');
      else
        el.html(el.data('text'));
    },//complete
    error: function () { alert('Server error!'); }//error
  });
});
// -----------------------------------------------------------------------------
});
