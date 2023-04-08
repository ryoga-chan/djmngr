(function ($) { $(function () {
// -----------------------------------------------------------------------------
new Freezeframe(); // show image animation only on mouseover

$.myapp = {
  nsfw_mode_setup: function () {
    var is_nsfw = localStorage['djmngr.nsfw-mode'] == 'true';
    $('body').toggleClass('nsfw-mode', is_nsfw);
    $('.nsfw-mode-toggle').find('i').text(is_nsfw ? 'remove_moderator' : 'shield');
  },//nsfw_mode_setup
  
  nsfw_mode_toggle: function () {
    localStorage['djmngr.nsfw-mode'] = !(localStorage['djmngr.nsfw-mode'] == 'true');
    $.myapp.nsfw_mode_setup();
  },//nsfw_mode_toggle
  
  show_loading: function () { $('nav.navbar').addClass('loading-bg');    },// show_loading
  
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
  
  // https://www.freecodecamp.org/news/javascript-keycode-list-keypress-event-key-codes/#a-full-list-of-key-event-values
  shortcuts: [
    { key: '?', ctrl: false, alt: false, descr: 'show shortcuts list', action:function (ev) {
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

      var n = Math.ceil($.myapp.shortcuts.length / 2);
      var html = '<div class="column is-half">' + build_table($.myapp.shortcuts.slice(0, n)) + '</div>' +
                 '<div class="column is-half">' + build_table($.myapp.shortcuts.slice(   n)) + '</div>';
      $.myapp.show_generic_modal('Page shortcuts', '<div class="columns">'+html+'</div>');
    } },
    { key: 'n', ctrl: false, alt: false, descr: 'toggle NFSW mode', action:function (ev) { $.myapp.nsfw_mode_toggle(); } },
    { key: 'h', ctrl: false, alt: false, descr: 'show Home', action: function (ev) { $.myapp.show_loading(); window.location = '/'; } },
    { key: 's', ctrl: false, alt: false, descr: 'global search focus', action: function (ev) { $('#global-search').focus().get(0).select(); } },
    { key: 'S', ctrl: false, alt: false, descr: 'show Settings', action: function (ev) { $.myapp.show_loading(); window.location = '/home/settings'; } },
    { key: 'b', ctrl: false, alt: false, descr: 'browse collection', action: function (ev) { $.myapp.show_loading(); window.location = '/doujinshi'; } },
    { key: 'p', ctrl: false, alt: false, descr: 'show Process', action: function (ev) { $.myapp.show_loading(); window.location = '/process'; } },
    { key: 'r', ctrl: false, alt: false, descr: 'show random book', action: function (ev) { $.myapp.show_loading(); window.location = '/doujinshi/random_pick?type=book'; } },
    { key: 'R', ctrl: false, alt: false, descr: 'show random best book', action: function (ev) { $.myapp.show_loading(); window.location = '/doujinshi/random_pick?type=scored'; } },
    { key: 'c', ctrl: false, alt: false, descr: 'show Compare', action: function (ev) { $.myapp.show_loading(); window.location = '/doujinshi/compare'; } }
  ]//shortcuts
}//$.myapp

// bind keyboard shortcuts
$('body').on('keydown', function (ev) {
  if (ev.key == 'Escape') {
    // close generic modal if opened
    if ($('#generic-modal').hasClass('is-active'))
      $.myapp.hide_generic_modal();
    
    // remove focus from current input
    if ($(document.activeElement).is(':input'))
      $(document.activeElement).blur();
    
    return false;
  }// Escape
  
  if ($(document.activeElement).is(':input'))
    return true;
  
  //console.log([ev.key, ev.ctrlKey, ev.altKey]);
  
  // close generic modal if opened
  if (ev.key == 'Escape' && $('#generic-modal').hasClass('is-active')) {
    $.myapp.hide_generic_modal();
    return false;
  }//if
  
  // execute each corresponding action
  $.each($.myapp.shortcuts, function (i, s) {
    if (ev.key == s.key && ev.ctrlKey == s.ctrl && ev.altKey == s.alt) {
      ev.preventDefault();
      s.action(ev);
    }//if
  });
});

// add spinner to navbar when clicking internal links
$('a[href]:not(.no-spinner, .run-progr, [target="_blank"], [href^="#"])').click(function (ev) {
  if (!ev.ctrlKey && !ev.altKey)
    $.myapp.show_loading();
});
// add spinner to navbar when submitting forms
$('form').submit(function (ev) { $.myapp.show_loading(); });
// onload page remove navbar spinner if present
$.myapp.hide_loading();

// temporarily disable "run external program" button when clicked
$('body').on('click', '.run-progr', function (ev) {
  var bt = $(this).addClass('is-loading');
  var s = bt.data('spin-time') ? parseInt(bt.data('spin-time')) : 5;
  setTimeout(function () { bt.removeClass('is-loading') }, s * 1000);
});

// apply sfw-mode if previously selected
$.myapp.nsfw_mode_setup();
// bind toggle sfw-mode button
$('a.nsfw-mode-toggle').click(function (ev) {
  ev.preventDefault();
  $.myapp.nsfw_mode_toggle();
});
// -----------------------------------------------------------------------------
}); })(jQuery)
