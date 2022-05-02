(function ($) { $(function () {
// ------------------------------------------------------------------------
if ($('body').data('ctrl') != 'doujinshi')
  return;

var p_bar = '<progress class="progress is-small is-info" max="100">i</progress>';

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
        el.data('text', el.html()).html(p_bar);
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

// show cover on mouseover
$('table.dj-details tbody tr').
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

if ($('body').data('action') == 'index') {
  // scroll menu to selected entry
  var sel_entry = $('.menu .is-active');
  if (sel_entry.length > 0)
    $('.menu').scrollTop( sel_entry.position().top - $('.menu').position().top );
}// action index

if ($('body').data('action') == 'show') {
  // update scoring
  $('.scoring > .icon').click(function () {
    $('.scoring').hide().after(p_bar);
    $('#score').val( $(this).data('score') ).get(0).form.submit();
  });
}// action show
// ------------------------------------------------------------------------
}); })(jQuery)
