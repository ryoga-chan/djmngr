console.info('LOADING controllers/metadata.js');

$(function () {
// -----------------------------------------------------------------------------
if ($.inArray($('body').data('ctrl'), ['authors', 'circles', 'themes']) < 0)
  return;

if ($('body').data('action') == 'show') {
  // add page shortcuts
  MyApp.shortcuts.push({ key: 'e', ctrl: false, alt: false, descr: 'edit details', action: function (ev) { MyApp.show_loading(); $('a.bt-edit').get(0).click(); } });
}// action show

if ($.inArray($('body').data('action'), ['new', 'edit']) >= 0) {
  console.log('haha');
  // add page shortcuts
  MyApp.shortcuts.push({ key: 's', ctrl: true, alt: false, descr: 'save details', action: function (ev) { MyApp.show_loading(); $('section.main-content form:first').submit(); } });
}// action edit
// -----------------------------------------------------------------------------
});
