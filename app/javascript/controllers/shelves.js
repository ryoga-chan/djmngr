console.info('imported: controllers/shelves');

import 'libs/app-setup';
import 'libs/sortable-jquery';

$(function () {
// -----------------------------------------------------------------------------
if ($('body').data('ctrl') != 'shelves')
  return;

if ($('body').data('action') == 'edit') {
  $('.doujin').on('click', 'a.toggle-remove', function (ev) {
    ev.preventDefault();
    
    var d = $(this).parents('.doujin');
    
    if (d.hasClass('removed'))
      d.removeClass('removed').find('.destroy').attr('disabled', 'disabled');
    else
      d.addClass('removed').find('.destroy').removeAttr('disabled');
  });
  
  $('.sortable').sortable({
    animation:  150,
    ghostClass: 'has-background-primary',
    filter: '.actions a',
    onUpdate: function (ev) {
      // set position on all items by their index
      $('.doujin .position').each(function (i) { $(this).val(i); })
    }//onUpdate
  });
}// action index
// -----------------------------------------------------------------------------
});
