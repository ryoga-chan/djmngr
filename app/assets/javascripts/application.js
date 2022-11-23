//= require jquery
//= require rails-ujs
//= require sortable
//= require jquery-sortable

//= require js-tagger
//= require favorites
//= require process
//= require doujinshi
//= require shelves

// SOURCES:
//   - rails-ujs:       https://github.com/rails/rails/blob/main/actionview/app/assets/javascripts/rails-ujs.js  (link from https://github.com/rails/rails-ujs)
//   - sortable:        https://github.com/SortableJS/Sortable
//   - jquery-sortable: https://github.com/SortableJS/jquery-sortablejs

(function ($) { $(function () {
// ------------------------------------------------------------------------
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
// ------------------------------------------------------------------------
}); })(jQuery)
