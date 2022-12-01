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
  show_loading: function () {
    $('section.main-content').
      html('<progress class="progress is-primary" max="100">loading...</progress>');
  }// show_loading
}//$.myapp

$('#appNavbar a[href]').click(function (ev) {
  if (!ev.ctrlKey && !ev.altKey)
    $.myapp.show_loading();
});

// temporary disable "run external program" button
$('body').on('click', '.run-progr', function (ev) {
  var bt = $(this).addClass('is-loading');
  setTimeout(function () { bt.removeClass('is-loading') }, 5000);
});
// -----------------------------------------------------------------------------
}); })(jQuery)
