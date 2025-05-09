console.info('imported: controllers/home');

import 'libs/app-setup';

$(function () {
// -----------------------------------------------------------------------------
if ($('body').data('ctrl') != 'home')
  return;

if ($('body').data('action') == 'index') {
  $('#load_recent').click(function (ev) {
    ev.preventDefault();
    
    var bt = $(this);
    var container = $('#recent_djs');
    var page = parseInt(bt.data('page')) + 1;
    
    $.ajax({
      url: bt.attr('href'),
      data: { page: page },
      dataType: 'html',
      cache: false,
      beforeSend: function () {
        container.removeClass('is-hidden');
        bt.addClass('is-loading');
      },//beforeSend
      success: function (resp) {
        bt.data('page', page);
        container.append(resp).load_ondemand_images({freezeframe: true});
      },//success
      complete: function () {
        bt.removeClass('is-loading');
      },//complete
      error: function () { alert('Server error!'); }//error
    });
  });
}// action index
// -----------------------------------------------------------------------------
});
