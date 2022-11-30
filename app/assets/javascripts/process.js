(function ($) { $(function () {
// -----------------------------------------------------------------------------
if ($('body').data('ctrl') +'/'+ $('body').data('action') != 'process/edit')
  return;

var p_bar = '<progress class="progress is-small is-info" max="100">i</progress>';

// keep file names button: toggle hidden checkbox and icon
$('#bt_keep_names').click(function () {
  $('#keep_names').prop('checked', !$('#keep_names').prop('checked'));
  $(this).find('i').text($('#keep_names').prop('checked') ? 'check_box' : 'check_box_outline_blank');
});

// massive rename with regexp
$('#rename_with').change(function () {
  var method = $(this).val();
  
  $('#rename_regexp'     ).parent().toggleClass('is-hidden', !method.match(/^regex/)      );
  $('#rename_regexp_repl').parent().toggleClass('is-hidden', method != 'regex_replacement');
  
  // insert default sample regexp or keep the previous one
  if (!$('#rename_regexp').data('last-value')) {
    if (method == 'regex_number'     ) $('#rename_regexp').val('([0-9]+)');
    if (method == 'regex_pref_num'   ) $('#rename_regexp').val('(.+[^0-9])([0-9]+)');
    if (method == 'regex_num_pref'   ) $('#rename_regexp').val('([0-9]+)([^0-9].+)');
    if (method == 'regex_replacement') $('#rename_regexp').val('');
  }//if
  
  if (method.match(/^regex/))
    $('#rename_regexp').focus().select();
});

// select images to delete
$('.images .columns .column').click(function (ev) {
  if ($(ev.target).is(':input, a'))
    return;
  
  $(this).toggleClass('has-background-warning');
  
  var cb = $(this).find(':checkbox');
  cb.prop('checked', !cb.prop('checked'));
});

// update the single image name in "files"
$('input[name="file_name"], input[name="img_name"]').change(function () {
  var el = $(this);
  
  $.ajax({
    url: el.data('url'),
    data: {
      name: el.val(),
      path: el.data('path')
    },
    method: 'POST',
    dataType: 'json',
    cache: false,
    beforeSend: function () { el.addClass('is-hidden').after(p_bar); },//beforeSend
    success: function (resp) {
      if (resp.result != 'ok')
        alert(resp.msg || 'Server error!');
    },//success
    complete: function () { el.removeClass('is-hidden').next().remove(); },//complete
    error: function () { alert('Server error!'); }//error
  });
});

// set scoring
$('.scoring span.icon[data-score]').click(function () {
  $('#score').val( $(this).data('score') );
  
  if ($(this).hasClass('clear-score')) // clear scoring status
    $('.scoring span.icon[data-score]:not(.clear-score)').removeClass('has-text-warning').find('i').text('star_outline');
  else { // change star color and filling
    $(this).prevAll('span.icon[data-score]').addBack().addClass('has-text-warning').find('i').text('star_rate');
    $(this).nextAll('span.icon[data-score]:not(.clear-score)').removeClass('has-text-warning').find('i').text('star_outline');
  }//if-else
  
  $('.scoring').after(p_bar);
  $(this).parents('form:first').submit();
});
// -----------------------------------------------------------------------------
}); })(jQuery)
