(function ($) { $(function () {
// ------------------------------------------------------------------------
if ($('body').data('ctrl') +'/'+ $('body').data('action') != 'process/edit')
  return;

$('#rename_with').change(function () {
  var method = $(this).val();
  
  $('#rename_regexp')
    .parent()
    .toggleClass('is-hidden', !method.match(/^regex/) );
  
  // insert default sample regexp or keep the previous one
  if (!$('#rename_regexp').data('last-value')) {
    if (method == 'regex_number'  ) $('#rename_regexp').val('([0-9]+)');
    if (method == 'regex_pref_num') $('#rename_regexp').val('(.+[^0-9])([0-9]+)');
    if (method == 'regex_num_pref') $('#rename_regexp').val('([0-9]+)([^0-9].+)');
  }//if
});

// select images to delete
$('.columns .column').click(function () {
  $(this).toggleClass('has-background-warning');
  
  var cb = $(this).find(':checkbox');
  cb.prop('checked', !cb.prop('checked'));
});
// ------------------------------------------------------------------------
}); })(jQuery)
