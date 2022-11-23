(function ($) { $(function () {
// -----------------------------------------------------------------------------
if ($('body').data('ctrl') != 'doujinshi')
  return;

var p_bar = '<progress class="progress is-small is-info" max="100">i</progress>';

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
  
  // add doujin to a shelf
  $('#shelf_id').change(function (ev) {
    var sel = $(this);
    
    if (sel.val() == '0') {
      var name = (prompt('New shelf name:') || '').trim();
      
      // NOOP if empty
      if (name.length == 0) {
        sel.val('');
        return;
      }//if
      
      $('#shelf_name').val(name);
    }//if
    
    // show spinner
    $('td.shelves .columns').hide().after(p_bar);
    
    this.form.submit();
  });
  
  // remove doujin from shelf: show spinner
  $('td.shelves .columns a.is-delete').click(function () {
    $('td.shelves .columns').hide().after(p_bar);
  });
}// action show
// -----------------------------------------------------------------------------
}); })(jQuery)
