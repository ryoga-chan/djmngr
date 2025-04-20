console.info('imported: libs/app-onload');

import 'libs/app-setup';

$(function () {
// -----------------------------------------------------------------------------
// show image animation only on mouseover
$(".freezeframe img, img.freezeframe").freeze_frame();

// bind keyboard shortcuts
$('body').on('keydown', function (ev) {
  //console.log([ev.key, ev.ctrlKey, ev.altKey]);

  if (ev.key == 'Escape') {
    // close generic modal if opened
    if ($('#generic-modal').hasClass('is-active'))
      MyApp.hide_generic_modal();
    
    // close ehentai-search modal if opened
    // TODO: merge ehentai-dialog with the generic one
    if ($('#ehentai-search-modal').hasClass('is-active'))
      $('#ehentai-search-modal button.delete').click();
    
    // remove focus from current input
    if ($(document.activeElement).is(':input'))
      $(document.activeElement).blur();
    
    return false;
  }// Escape
  
  if ($(document.activeElement).is(':input') && !ev.ctrlKey && !ev.altKey)
    return true;
  
  // execute each corresponding action
  $.each(MyApp.shortcuts, function (i, s) {
    if (ev.key == s.key && ev.ctrlKey == s.ctrl && ev.altKey == s.alt) {
      ev.preventDefault();
      s.action(ev);
    }//if
  });
});// bind keyboard shortcuts

// add spinner to navbar when clicking internal links
$('a[href]:not(.no-spinner, .run-progr, [target="_blank"], [href^="#"])').click(function (ev) {
  if (!ev.ctrlKey && !ev.altKey)
    MyApp.show_loading();
});
// add spinner to navbar when submitting forms
$('form').submit(function (ev) { MyApp.show_loading(); });
// remove spinner on navbar if present on page load
MyApp.hide_loading();

// temporarily disable "run external program" button when clicked
$('body').on('click', '.run-progr', function (ev) {
  var bt = $(this).addClass('is-loading');
  var s = bt.data('spin-time') ? parseInt(bt.data('spin-time')) : 5;
  setTimeout(function () { bt.removeClass('is-loading') }, s * 1000);
});

// apply sfw-mode if previously selected
MyApp.nsfw_mode_setup();

// toggle sfw-mode button
$('a.nsfw-mode-toggle').click(function (ev) {
  ev.preventDefault();
  MyApp.nsfw_mode_toggle();
});
// -----------------------------------------------------------------------------
});
