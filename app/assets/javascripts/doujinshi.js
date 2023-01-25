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
  // add page shortcuts
  $.myapp.shortcuts.push({ key: 'e', ctrl: false, alt: false, descr: 'edit details', action: function (ev) { $.myapp.show_loading(); $('a.bt-edit').get(0).click(); } });
  $.myapp.shortcuts.push({ key: 's', ctrl: true, alt: false, descr: 'show sample pages', action: function (ev) { $.myapp.show_loading(); $('a.bt-sample').get(0).click(); } });
  $.myapp.shortcuts.push({ key: 'r', ctrl: true, alt: false, descr: 'read doujin', action: function (ev) { $.myapp.show_loading(); $('a.bt-read').get(0).click(); } });
  $.myapp.shortcuts.push({ key: 'R', ctrl: true, alt: false, descr: 'run external reader', action: function (ev) { $('a.bt-reader').get(0).click(); } });
  $.myapp.shortcuts.push({ key: 't', ctrl: true, alt: false, descr: 'open terminal', action: function (ev) { $('a.bt-term').get(0).click(); } });
  $.myapp.shortcuts.push({ key: 'f', ctrl: true, alt: false, descr: 'open file manager', action: function (ev) { $('a.bt-fm').get(0).click(); } });
  for (let i = 1; i <= 10; i++)
    $.myapp.shortcuts.push({ key: i.toString(), ctrl: false, alt: false, descr: 'assign score 1', action: function (ev) { $('span.set-score[data-score="'+i+'"]').get(0).click(); } });
  $.myapp.shortcuts.push({ key: '0', ctrl: false, alt: false, descr: 'clear scoring', action: function (ev) { $('span.clear-score').get(0).click(); } });
  
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

if ($('body').data('action') == 'edit') {
  // add page shortcuts
  $.myapp.shortcuts.push({ key: 's', ctrl: true, alt: false, descr: 'save details', action: function (ev) { $.myapp.show_loading(); $('section.main-content form:first').submit(); } });
}// action edit
// -----------------------------------------------------------------------------
}); })(jQuery)
