(function ($) { $(function () {
// -----------------------------------------------------------------------------
if ($.inArray($('body').data('ctrl'), ['authors', 'circles', 'themes']) < 0)
  return;

if ($('body').data('action') == 'show') {
  // add page shortcuts
  $.myapp.shortcuts.push({ key: 'e', ctrl: false, alt: false, descr: 'edit details', action: function (ev) { $.myapp.show_loading(); $('a.bt-edit').get(0).click(); } });
}// action show

if ($.inArray($('body').data('action'), ['new', 'edit']) >= 0) {
  console.log('haha');
  // add page shortcuts
  $.myapp.shortcuts.push({ key: 's', ctrl: true, alt: false, descr: 'save details', action: function (ev) { $.myapp.show_loading(); $('section.main-content form:first').submit(); } });
}// action edit
// -----------------------------------------------------------------------------
}); })(jQuery)
