(function ($) { $(function () {
// ------------------------------------------------------------------------
if ($('body').data('ctrl') != 'doujinshi')
  return;

var p_bar = '<progress class="progress is-small is-info" max="100">i</progress>';

if ($('body').data('action') == 'index') {
  // show cover on mouseover
  $('table.details tbody tr').
    mouseenter(function (ev) {
      const tr = $(ev.target).parents('tr:first');
      var pos = tr.offset();
      pos['top' ] += tr.height();
      pos['left'] += 10;
      $('#sample_cover').removeClass('is-hidden').attr('src', tr.data('cover')).css(pos);
    }).
    mouseleave(function (ev) {
      $('#sample_cover').addClass('is-hidden').removeAttr('src');
    });
}// action index

if ($('body').data('action') == 'show') {
  $('.scoring > .icon').click(function () {
    $('.scoring').hide().after(p_bar);
    $('#score').val( $(this).data('score') ).get(0).form.submit();
  });
}// action show
// ------------------------------------------------------------------------
}); })(jQuery)
