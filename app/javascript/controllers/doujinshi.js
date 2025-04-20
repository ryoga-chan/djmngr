console.info('imported: controllers/doujinshi');

import 'libs/app-setup';

import 'components/ehentai-search';
import 'components/js-finder';
import 'components/js-tagger';

$(function () {
// -----------------------------------------------------------------------------
if ($('body').data('ctrl') != 'doujinshi')
  return;

var p_bar = '<progress class="progress is-small is-info" max="100">i</progress>';

// show cover on mouseover
$('table.dj-details tbody tr > td.show-thumb').
  mouseenter(function (ev) {
    const tr = $(ev.target).parents('tr:first');
    var pos = tr.offset();
    pos['top' ] += tr.height();
    pos['left'] += 10;
    $('#sample_cover').removeClass('is-hidden').attr('src', tr.data('cover')).css(pos);
  }).
  mouseleave(function (ev) {
    $('#sample_cover').addClass('is-hidden').removeAttr('src');
  });

// add page shortcut to toggle table/thumbs results
if ($('a.bt-thumbs').length > 0)
  MyApp.shortcuts.push({ key: 't', ctrl: false, alt: false, descr: 'toggle thumbnails', action: function (ev) { var bt=$('a.bt-thumbs').get(0); if (bt) { MyApp.show_loading(); bt.click(); } } });

if ($('body').data('action') == 'index') {
  // add page shortcuts
  MyApp.shortcuts.push({ key: 'a', ctrl: false, alt: true, descr: 'show authors', action: function (ev) { MyApp.show_loading(); $('.tabs a[title="authors"]').get(0).click(); } });
  MyApp.shortcuts.push({ key: 'c', ctrl: false, alt: true, descr: 'show circles', action: function (ev) { MyApp.show_loading(); $('.tabs a[title="circles"]').get(0).click(); } });
  MyApp.shortcuts.push({ key: 'b', ctrl: false, alt: true, descr: 'show artbooks', action: function (ev) { MyApp.show_loading(); $('.tabs a[title="artbooks"]').get(0).click(); } });
  MyApp.shortcuts.push({ key: 'm', ctrl: false, alt: true, descr: 'show magazine', action: function (ev) { MyApp.show_loading(); $('.tabs a[title="magazines"]').get(0).click(); } });

  // scroll menu to selected entry
  var sel_entry = $('.menu .is-active');
  if (sel_entry.length > 0)
    $('.menu').scrollTop( sel_entry.position().top - $('.menu').position().top );

  // js-finder search callback
  $('a.js-finder').data('onselect', function (info) {
    $('#doujin_id').val(info.id);
  });
}// action index

if ($('body').data('action') == 'show') {
  // add page shortcuts
  MyApp.shortcuts.push({ key: 'e', ctrl: false, alt: false, descr: 'edit details', action: function (ev) { MyApp.show_loading(); $('a.bt-edit').get(0).click(); } });
  MyApp.shortcuts.push({ key: 's', ctrl: false, alt: true,  descr: 'show sample pages', action: function (ev) { MyApp.show_loading(); $('a.bt-sample').get(0).click(); } });
  MyApp.shortcuts.push({ key: 'r', ctrl: false, alt: true,  descr: 'read doujin', action: function (ev) { MyApp.show_loading(); $('a.bt-read').get(0).click(); } });
  MyApp.shortcuts.push({ key: 'e', ctrl: false, alt: true,  descr: 'run external reader', action: function (ev) { $('a.bt-reader').get(0).click(); } });
  MyApp.shortcuts.push({ key: 't', ctrl: false, alt: true,  descr: 'open terminal', action: function (ev) { $('a.bt-term').get(0).click(); } });
  MyApp.shortcuts.push({ key: 'f', ctrl: false, alt: true,  descr: 'open file manager', action: function (ev) { $('a.bt-fm').get(0).click(); } });
  MyApp.shortcuts.push({ key: '-', ctrl: false, alt: false, descr: 'clear scoring', action: function (ev) { $('span.clear-score').get(0).click(); } });
  for (let i = 1; i <= 9; i++)
    MyApp.shortcuts.push({ key: i.toString(), ctrl: false, alt: false, descr: 'assign score 1', action: function (ev) { $('span.set-score[data-score="'+i+'"]').get(0).click(); } });
  MyApp.shortcuts.push({ key: '0', ctrl: false, alt: false, descr: 'assign score 10', action: function (ev) { $('span.set-score[data-score="10"]').get(0).click(); } });
  
  // update scoring
  $('.scoring > .icon').click(function () {
    $('.scoring').hide().after(p_bar);
    $('#score').val( $(this).data('score') ).get(0).form.submit();
  });
  
  // add doujin to a shelf
  $('#shelf_id').change(function (ev) {
    var sel = $(this);
    
    if (sel.val() == '0') {
      var name = (prompt('New shelf name:') || '').trim();
      
      // NOOP if empty
      if (name.length == 0) {
        sel.val('');
        return;
      }//if
      
      $('#shelf_name').val(name);
    }//if
    
    // show spinner
    $('td.shelves .columns').hide().after(p_bar);
    
    this.form.submit();
  });
  
  // remove doujin from shelf: show spinner
  $('td.shelves .columns a.is-delete').click(function () {
    $('td.shelves .columns').hide().after(p_bar);
  });
}// action show

if ($('body').data('action') == 'edit') {
  MyApp.titles_to_lowercase = function () {
    $.each(['doujin_name', 'doujin_name_romaji', 'doujin_name_eng', 'doujin_file_name', 'doujin_name_orig'],
      function () { $('#'+this).val( $('#'+this).val().toLowerCase().trim() ); });
  }// MyApp.titles_to_lowercase

  MyApp.autotag_titles = function () {
    var tags = [];
    
    if ($('#doujin_language').val() != 'jpn' && $('#doujin_language').val() != '???')
      tags.push( $('#doujin_language').val() );
    
    if ($('#doujin_censored').val() == 'false')
      tags.push('unc');
    
    if ($('#doujin_colorized').val() == 'true')
      tags.push('col');
    
    tags = tags.length > 0 ? ` (${ tags.join(',') })` : '';
    
    var t = $('#doujin_name').val().replace(/ *\([^)]+\)$/, '').trim();
    $('#doujin_name').val(`${t}${tags}`);

    t = $('#doujin_file_name').val().replace(/ *\([^)]+\).zip$/, '').replace(/\.zip$/, '').trim();
    $('#doujin_file_name').val(`${t}${tags}.zip`);
    
    t = $('#doujin_name_romaji').val().replace(/ *\([^)]+\)$/, '').trim();
    if (t.length > 0)
      $('#doujin_name_romaji').val(`${t}${tags}`);
  }// MyApp.autotag_titles

  // add page shortcuts
  MyApp.shortcuts.push({ key: 's', ctrl: true, alt: false, descr: 'save details', action: function (ev) { MyApp.show_loading(); $('section.main-content form:first').submit(); } });
  MyApp.shortcuts.push({ key: 'l', ctrl: false, alt: false, descr: 'convert all titles to lowercase', action: function (ev) {
    $.each(
      ['doujin_name', 'doujin_name_romaji', 'doujin_name_kakasi', 'doujin_name_eng',
       'doujin_file_name', 'doujin_name_orig'],
      function () { $('#'+this).val( $('#'+this).val().toLowerCase() ); }
    );
  } });

  // ehentai search callback: place titles in kanji/romaji fields, and full text in notes field
  $('.ehentai-search').data('onselect', function (info) {
    $('#doujin_name').val(info.title_jpn_clean || info.title_clean);
    $('#doujin_notes').append( $('<div/>').html(info.title_jpn || info.title).text() + "\n" );
    
    if (info.title_jpn) {
      $('#doujin_name_romaji').val(info.title_clean);
      $('#doujin_notes').append( $('<div/>').html(info.title).text() + "\n" );
    }//if
    
    if (info.title_eng) {
      $('#doujin_name_eng').val(info.title_eng_clean);
      $('#doujin_notes').append( $('<div/>').html(info.title_eng).text() + "\n" );
    }//if
    
    MyApp.autotag_titles();
    MyApp.titles_to_lowercase();
  });
}// action edit

if ($('body').data('action') == 'compare') {
  // manage click on linked image: area1 = select image, area2 = open link
  $('table#compare img').split_click({
    //mode:  $('#frm-images').data('image-sel-mode'),
    area1: function (el, ev) {
      var page = el.parent().parent();
      page.clone().empty().addClass('gap').insertBefore(page);
    },//area1
    area2: function (el, ev) {
      var page = el.parent().parent();
      page.clone().empty().addClass('gap').insertAfter(page);
    }//area1
  });

  // remove gap onclick
  $('table#compare').on('click', 'div.gap', function () { $(this).remove(); });
}// action compare
// -----------------------------------------------------------------------------
});
