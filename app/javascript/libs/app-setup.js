console.info('imported: libs/app-setup');

import 'libs/jquery';     // sets window.{jQuery, $}
import 'libs/jquery-ujs'; // sets window.{jQuery, $}.rails
import 'libs/freeze_frame-jquery';

import 'components/img_ondemand_load';
import('components/img_sequential_load');

// --- shared functions and data -----------------------------------------------
// https://stackoverflow.com/questions/13383886/making-a-short-alias-for-document-queryselectorall/14947838#14947838
window.$q = window.document.querySelector   .bind(window.document);
window.$Q = window.document.querySelectorAll.bind(window.document);

window.MyApp = {
  p_bar: '<progress class="progress is-small is-info" max="100">i</progress>',
  
  nsfw_mode_setup: function () {
    var is_nsfw = localStorage['djmngr.nsfw-mode'] == 'true';
    $('body').toggleClass('nsfw-mode', is_nsfw);
    $('.nsfw-mode-toggle').find('i').text(is_nsfw ? 'remove_moderator' : 'shield');
  },//nsfw_mode_setup

  nsfw_mode_toggle: function () {
    localStorage['djmngr.nsfw-mode'] = !(localStorage['djmngr.nsfw-mode'] == 'true');
    MyApp.nsfw_mode_setup();
  },//nsfw_mode_toggle

  toggle_fullscreen: function () {
    if (document.fullscreenElement)
      document.exitFullscreen();
    else
      $('body').get(0).requestFullscreen();
  },//toggle_fullscreen

  show_loading: function () { $('nav.navbar').addClass('loading-bg'); },

  hide_loading: function () {
    $('nav.navbar').removeClass('loading-bg');
    
    // disable Firefox's bfcache (fix "go back in history" and JS not running)
    // https://stackoverflow.com/questions/2638292/after-travelling-back-in-firefox-history-javascript-wont-run
    window.onunload = function(){};
  },// hide_loading

  show_generic_modal: function (title, content) {
    $('#generic-modal').addClass('is-active').
      find('.modal-card-title').text(title).end().
      find('.modal-card-body').html(content);
  },// show_generic_modal

  hide_generic_modal: function () { $('#generic-modal').removeClass('is-active'); },

  // http://stackoverflow.com/a/30905277
  copy_to_clipboard: function (text) {
    MyApp.last_text_copied_to_clipboard = text; // local copy, clipboard API only work in HTTPS and localhost
    try { navigator.clipboard.writeText(text); }
    catch (err) { console.log(err); }
  },//copy_to_clipboard

  paste_clipboard: function (callback) {
    try { navigator.clipboard.readText().then(callback); }
    catch (err) { callback(MyApp.last_text_copied_to_clipboard || ''); }
  },//paste_clipboard

  append_to_textarea: function (selector, text) {
    var ta = $(selector);
    var new_text = ta.val().trim() + "\n" + $('<div/>').html(text).text();
    ta.val(new_text.trim());
  },//append_to_textarea

  translitterate: function (string, ajax_options) {
    $.ajax($.extend({
      url: '/ws/to_romaji',
      data: { s: string },
      method: 'GET',
      dataType: 'text',
      cache: false,
      error: function () { alert('Server error!'); }//error
    }, ajax_options));
  },//translitterate

  // https://www.freecodecamp.org/news/javascript-keycode-list-keypress-event-key-codes/#a-full-list-of-key-event-values
  shortcuts: [
    { key: '?', ctrl: false, alt: false, descr: 'show shortcuts list', action: function (ev) {
      function build_table (entries) {
        var text = '<table class="table is-striped is-narrow is-hoverable is-fullwidth">';
        text += '<tr><th>Combo</th><th>Action</th></tr>';
        $.each(entries, function (i, s) {
          text += '<tr><td class="nowrap">' +
                  (s.ctrl ? '<span class="tag is-primary">Ctrl</span> + ' : '') +
                  (s.alt ? '<span class="tag is-primary">Alt</span> + ' : '') +
                  '<span class="tag is-info">'+ s.key + '</span></td><td>' +
                  s.descr + '</td></tr>';
        });
        text += '</table>'
        return text;
      }// build_table

      var n = Math.ceil(MyApp.shortcuts.length / 2);
      var html = '<div class="column is-half">' + build_table(MyApp.shortcuts.slice(0, n)) + '</div>' +
                 '<div class="column is-half">' + build_table(MyApp.shortcuts.slice(   n)) + '</div>';
      MyApp.show_generic_modal('Page shortcuts', '<div class="columns">'+html+'</div>');
    } },
    { key: 'n', ctrl: false, alt: false, descr: 'toggle NFSW mode',    action: function (ev) { MyApp.nsfw_mode_toggle(); } },
    { key: 's', ctrl: false, alt: false, descr: 'global search focus', action: function (ev) { $('#global-search').focus().get(0).select(); } },
    { key: 'h', ctrl: false, alt: false, descr: 'show Home',           action: function (ev) { MyApp.show_loading(); window.location = '/'; } },
    { key: 'S', ctrl: false, alt: false, descr: 'show Settings',       action: function (ev) { MyApp.show_loading(); window.location = '/home/settings'; } },
    { key: 'b', ctrl: false, alt: false, descr: 'browse collection',   action: function (ev) { MyApp.show_loading(); window.location = '/doujinshi'; } },
    { key: 'p', ctrl: false, alt: false, descr: 'show Process',        action: function (ev) { MyApp.show_loading(); window.location = '/process'; } },
    { key: 'r', ctrl: false, alt: false, descr: 'random book',         action: function (ev) { MyApp.show_loading(); window.location = '/doujinshi/random_pick?type=books'; } },
    { key: 'R', ctrl: false, alt: false, descr: 'random best book',    action: function (ev) { MyApp.show_loading(); window.location = '/doujinshi/random_pick?type=best'; } },
    { key: 'c', ctrl: false, alt: false, descr: 'show Compare',        action: function (ev) { MyApp.show_loading(); window.location = '/doujinshi/compare'; } }
  ],//shortcuts
};//window.MyApp
