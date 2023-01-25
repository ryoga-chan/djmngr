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
  
  show_loading: function () {
    $('section.main-content > *').hide();
    $('section.main-content').prepend('<progress class="progress is-primary" max="100">loading...</progress>');
  },// show_loading
  
  show_generic_modal: function (title, content) {
    $('#generic-modal').addClass('is-active').
      find('.modal-card-title').text(title).end().
      find('.modal-card-body').html(content);
  },// show_generic_modal
  
  hide_generic_modal: function () { $('#generic-modal').removeClass('is-active'); },
  
  shortcuts: [
    { key: '?', ctrl: false, alt: false, descr: 'show shortcuts list', action:function (ev) {
      var text = '<table class="table is-striped is-narrow is-hoverable is-fullwidth">';
      text += '<tr><th>Combo</th><th>Action</th></tr>';
      $.each($.myapp.shortcuts, function (i, s) {
        text += '<tr><td>' + (s.ctrl ? 'Ctrl + ' : '') + (s.alt ? 'Alt + ' : '') + s.key + '</td><td>' + s.descr + '</td></tr>';
      });
      text += '</table>'
      $.myapp.show_generic_modal('Page shortcuts', text);
    } },
    { key: 'n', ctrl: false, alt: false, descr: 'toggle NFSW mode', action:function (ev) { $.myapp.nsfw_mode_toggle(); } },
    { key: 'h', ctrl: false, alt: false, descr: 'show Home', action: function (ev) { $.myapp.show_loading(); window.location = '/'; } },
    { key: 's', ctrl: false, alt: false, descr: 'global search focus', action: function (ev) { $('#global-search').focus().get(0).select(); } },
    { key: 'S', ctrl: false, alt: false, descr: 'show Settings', action: function (ev) { $.myapp.show_loading(); window.location = '/home/settings'; } },
    { key: 'b', ctrl: false, alt: false, descr: 'browse collection', action: function (ev) { $.myapp.show_loading(); window.location = '/doujinshi'; } },
    { key: 'p', ctrl: false, alt: false, descr: 'show Process', action: function (ev) { $.myapp.show_loading(); window.location = '/process'; } },
    { key: 'r', ctrl: false, alt: false, descr: 'show random book', action: function (ev) { $.myapp.show_loading(); window.location = '/doujinshi/random_pick?type=book'; } },
    { key: 'R', ctrl: false, alt: false, descr: 'show random best book', action: function (ev) { $.myapp.show_loading(); window.location = '/doujinshi/random_pick?type=scored'; } }
  ]//shortcuts
}//$.myapp

// bind keyboard shortcuts
$('body').on('keydown', function (ev) {
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

$('#appNavbar a[href]:not(.no-spinner)').click(function (ev) {
  if (!ev.ctrlKey && !ev.altKey)
    $.myapp.show_loading();
});

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
