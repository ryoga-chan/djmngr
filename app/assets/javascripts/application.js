//= require jquery
//= require rails-ujs
//= require js-tagger
//= require favorites
//= require process
//= require doujinshi

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
