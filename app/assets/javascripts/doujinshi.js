(function ($) { $(function () {
// ------------------------------------------------------------------------
if ($('body').data('ctrl') +'/'+ $('body').data('action') != 'doujinshi/index')
  return;

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
// ------------------------------------------------------------------------
}); })(jQuery)
