//= require libs/jquery
//= require libs/rails-ujs
//= require libs/sortable
//= require libs/jquery-sortable
//= require libs/freezeframe

//= require js-tagger
//= require favorites
//= require process
//= require doujinshi
//= require shelves

// SOURCES:
//   - rails-ujs        https://github.com/rails/rails/blob/main/actionview/app/assets/javascripts/rails-ujs.js  (link from https://github.com/rails/rails-ujs)
//   - sortable         https://github.com/SortableJS/Sortable
//   - jquery-sortable  https://github.com/SortableJS/jquery-sortablejs
//   - freezeframe      https://github.com/ctrl-freaks/freezeframe.js/tree/master/packages/freezeframe

(function ($) { $(function () {
// -----------------------------------------------------------------------------
new Freezeframe(); // show image animation only on mouseover

$.myapp = {
  nsfw_mode_setup: function () {
    var is_nsfw = localStorage['djmngr.nsfw-mode'] == 'true';
    $('body').toggleClass('nsfw-mode', is_nsfw);
    $('.nsfw-mode-toggle').find('i').text(is_nsfw ? 'remove_moderator' : 'shield');
  },//nsfw_mode_setup
  
  show_loading: function () {
    $('section.main-content').
      html('<progress class="progress is-primary" max="100">loading...</progress>');
  }// show_loading
}//$.myapp

$('#appNavbar a[href]:not(.no-spinner)').click(function (ev) {
  if (!ev.ctrlKey && !ev.altKey)
    $.myapp.show_loading();
});

// temporarily disable "run external program" button when clicked
$('body').on('click', '.run-progr', function (ev) {
  var bt = $(this).addClass('is-loading');
  setTimeout(function () { bt.removeClass('is-loading') }, 5000);
});

// apply sfw-mode if previously selected
$.myapp.nsfw_mode_setup();
// bind toggle sfw-mode button
$('a.nsfw-mode-toggle').click(function (ev) {
  ev.preventDefault();
  localStorage['djmngr.nsfw-mode'] = !(localStorage['djmngr.nsfw-mode'] == 'true');
  $.myapp.nsfw_mode_setup();
});
// -----------------------------------------------------------------------------
}); })(jQuery)
