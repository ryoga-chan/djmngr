(function ($) { $(function () {
// -----------------------------------------------------------------------------
if ($('body').data('ctrl') != 'process')
  return;

var p_bar = '<progress class="progress is-small is-info" max="100">i</progress>';

$.myapp.titles_to_lowercase = function () {
  $.each(['dest_title', 'dest_title_romaji', 'dest_title_eng', 'dest_filename'],
    function () { $('#'+this).val( $('#'+this).val().toLowerCase().trim() ); });
}// $.myapp.titles_to_lowercase

$.myapp.translitterate_raw_title = function () {
  var dst = $('#dest_title_romaji');
  $.myapp.translitterate($('#dest_title').val(), {
    beforeSend: function () {
      dst.addClass('is-hidden').
        after( $(p_bar).addClass('fillwidth').css('display', 'inline-block') );
    },//beforeSend
    success: function (resp) { dst.val(resp); },//success
    complete: function () { dst.removeClass('is-hidden').next().remove(); },//complete
  });
}// $.myapp.titles_to_lowercase

$.myapp.autotag_titles = function () {
  var tags = [];
  
  if ($('#language').val() != 'jpn' && $('#language').val() != '???')
    tags.push( $('#language').val() );
  
  if ($('#censored').val() == 'false')
    tags.push('unc');
  
  if ($('#colorized').val() == 'true')
    tags.push('col');
  
  tags = tags.length > 0 ? ` (${ tags.join(',') })` : '';
  
  var t = $('#dest_title').val().replace(/ *\([^)]+\)$/, '').trim();
  $('#dest_title').val(`${t}${tags}`);
  
  t = $('#dest_title_romaji').val().replace(/ *\([^)]+\)$/, '').trim();
  if (t.length > 0)
    $('#dest_title_romaji').val(`${t}${tags}`);
}// $.myapp.autotag_titles

// remote update the name in "files", "images", and "batch" sections
$('input.update-name').change(function () {
  var el = $(this);
  
  $.ajax({
    url: el.data('url'),
    data: {
      name: el.val().trim(),
      path: el.data('path')
    },
    method: 'POST',
    dataType: 'json',
    cache: false,
    beforeSend: function () {
      el.val( el.val().trim() );
      el.addClass('is-hidden').after(p_bar);
    },//beforeSend
    success: function (resp) {
      if (resp.result != 'ok')
        alert(resp.msg || 'Server error!');
    },//success
    complete: function () { el.removeClass('is-hidden').next().remove(); },//complete
    error: function () { alert('Server error!'); }//error
  });
});

// remote update notes for ProcessableDoujin
$('input.pd-notes').change(function () {
  var el = $(this);
  
  $.ajax({
    url: el.data('url'),
    data: { text: el.val().trim() },
    method: 'POST',
    dataType: 'json',
    cache: false,
    beforeSend: function () {
      el.val( el.val().trim() );
      el.addClass('is-hidden').after(p_bar);
    },//beforeSend
    success: function (resp) {
      if (resp.result != 'ok')
        alert(resp.msg || 'Server error!');
    },//success
    complete: function () { el.removeClass('is-hidden').next().remove(); },//complete
    error: function () { alert('Server error!'); }//error
  });
});


if ($('body').data('ctrl') +'/'+ $('body').data('action') == 'process/index') {
  // add page shortcuts
  $.myapp.shortcuts.push({ key: 'b', ctrl: false, alt: true, descr: 'toggle batch mode', action: function (ev) { $('a.bt-batch').get(0).click(); } });
  $.myapp.shortcuts.push({ key: 't', ctrl: false, alt: true, descr: 'toggle checked entries for batch', action: function (ev) { $('a.bt-toggle-all').get(0).click(); } });
  $.myapp.shortcuts.push({ key: 'r', ctrl: false, alt: true, descr: 'refresh entries index', action: function (ev) { $('a.bt-reindex').get(0).click(); } });
  
  $.app = $.extend($.app, {
    update_tot_filesize: function () {
      var tot_bytes = 0;
      $('.file-select :checkbox:checked').each(function(){ tot_bytes += $(this).data('size'); });
      // update confirm deletion message
      var msg = $('button.batch-delete').data('msg').
        replace('NUM' , $('.file-select :checkbox:checked').length).
        replace('SIZE', tot_bytes > 0 ? '~'+(tot_bytes / 1024 / 1024).toFixed(0)+'MB' : '');
      $('button.batch-delete').data('confirm', msg).attr('data-confirm', msg);
    }//update_tot_filesize
  });
  
  // update total file size label
  $('.file-select').click($.app.update_tot_filesize);
  
  // fade out and remove the ungrouped entry in group mode
  $('.grop-actions a.remove').on('ajax:success', function (ev) {
    let [resp, status, jxhr] = ev.originalEvent.detail;
    var rows = $(`tr[data-group-item-id="${resp.id}"]`).next().addBack();
    rows.fadeOut(function () { rows.remove(); });
  });
}//if /process/index


if ($('body').data('ctrl') +'/'+ $('body').data('action') == 'process/edit') {
  // add page shortcuts - switch active tab
  $.myapp.shortcuts.push({ key: 'd', ctrl: false, alt: true, descr: 'switch tab to Dupes'   , action: function (ev) { $.myapp.show_loading(); $('#tab-dupes' ).get(0).click(); } });
  $.myapp.shortcuts.push({ key: 'n', ctrl: false, alt: true, descr: 'switch tab to Names'   , action: function (ev) { $.myapp.show_loading(); $('#tab-files' ).get(0).click(); } });
  $.myapp.shortcuts.push({ key: 'p', ctrl: false, alt: true, descr: 'switch tab to Pics'    , action: function (ev) { $.myapp.show_loading(); $('#tab-images').get(0).click(); } });
  $.myapp.shortcuts.push({ key: 'i', ctrl: false, alt: true, descr: 'switch tab to Identify', action: function (ev) { $.myapp.show_loading(); $('#tab-ident' ).get(0).click(); } });
  $.myapp.shortcuts.push({ key: 'f', ctrl: false, alt: true, descr: 'switch tab to Finalize', action: function (ev) { $.myapp.show_loading(); $('#tab-move'  ).get(0).click(); } });
  // add page shortcuts - tab identify - focus on search field
  $.myapp.shortcuts.push({
    key: 'f', ctrl: false, alt: false, descr: 'Identify search focus',
    action: function (ev) {
      var el = $('#process-ident-search').focus().get(0);
      if (el) el.select();
    }//action
  });
  // add page shortcuts - tab move
  $.myapp.shortcuts.push({ key: 't', ctrl: false, alt: false, descr: 'focus on raw title', action: function (ev) { $('#dest_title').focus(); } });
  $.myapp.shortcuts.push({ key: 'r', ctrl: false, alt: true , descr: 'copy kanji title to filename'  , action: function (ev) { $('#dest_filename').val( $('#dest_title'       ).val().trim() + '.zip' ); } });
  $.myapp.shortcuts.push({ key: 't', ctrl: false, alt: true , descr: 'copy romaji title to filename' , action: function (ev) { $('#dest_filename').val( $('#dest_title_romaji').val().trim() + '.zip' ); } });
  $.myapp.shortcuts.push({ key: 'e', ctrl: false, alt: true , descr: 'copy english title to filename', action: function (ev) { $('#dest_filename').val( $('#dest_title_eng'   ).val().trim() + '.zip' ); } });
  $.myapp.shortcuts.push({ key: 'l', ctrl: false, alt: false, descr: 'convert all titles to lowercase', action: $.myapp.titles_to_lowercase });
  $.myapp.shortcuts.push({ key: 'Enter', ctrl: false, alt: true , descr: 'finalize archive', action: function (ev) { $('.actions button[value="finalize"]').get(0).click(); } });
  $.myapp.shortcuts.push({ key: 'Enter', ctrl: true , alt: false, descr: 'update info', action: function (ev) { $('.actions button[value="save"]').get(0).click(); } });
  // add page shortcuts - scoring
  $.myapp.shortcuts.push({ key: '-', ctrl: false, alt: false, descr: 'clear scoring', action: function (ev) { $('span.clear-score').get(0).click(); } });
  for (let i = 1; i <= 9; i++)
    $.myapp.shortcuts.push({ key: i.toString(), ctrl: false, alt: false, descr: 'assign score '+i, action: function (ev) { $('span.set-score[data-score="'+i+'"]').get(0).click(); } });
  $.myapp.shortcuts.push({ key: '0', ctrl: false, alt: false, descr: 'assign score 10', action: function (ev) { $('span.set-score[data-score="10"]').get(0).click(); } });
  // add page shortcuts - tab pics
  $.myapp.shortcuts.push({ key: 'd', ctrl: false, alt: false, descr: 'delete selected images', action: function (ev) { var bt=$('button.delete-images:first').get(0); if (bt) bt.click(); } });
  
  // keep file names button: toggle hidden checkbox and icon
  $('#bt_keep_names').click(function () {
    $('#keep_names').prop('checked', !$('#keep_names').prop('checked'));
    $(this).find('i').text($('#keep_names').prop('checked') ? 'check_box' : 'check_box_outline_blank');
  });

  // massive rename with regexp
  $('#rename_with').change(function () {
    var method = $(this).val();
    
    $('#rename_regexp'     ).parent().toggleClass('is-hidden', !method.match(/^regex/)      );
    $('#rename_regexp_repl').parent().toggleClass('is-hidden', method != 'regex_replacement');
    
    // insert default sample regexp or keep the previous one
    if (!$('#rename_regexp').data('last-value')) {
      if (method == 'regex_number'     ) $('#rename_regexp').val('([0-9]+)');
      if (method == 'regex_pref_num'   ) $('#rename_regexp').val('(.+[^0-9])([0-9]+)');
      if (method == 'regex_num_pref'   ) $('#rename_regexp').val('([0-9]+)([^0-9].+)');
      if (method == 'regex_replacement') $('#rename_regexp').val('');
    }//if
    
    if (method.match(/^regex/))
      $('#rename_regexp').focus().select();
  });

  // select images to delete
  $('.images .button.select-image').click(function (ev) {
    // toggle column background color and button icon
    $(this).parent().toggleClass('has-background-warning');
    $(this).find('i').text( $(this).parent().hasClass('has-background-warning') ? 'check_box' : 'check_box_outline_blank');
    
    // toggle hidden checkbox
    var cb = $(this).parent().find(':checkbox');
    cb.prop('checked', !cb.prop('checked'));
    
    // update counter message
    var num_images = $('.images .columns .column.has-background-warning').length;
    $('button.delete-images').attr('data-confirm', 'Delete '+num_images+' selected images?');
  });
  
  // show export to folder list + populate paths[]
  $('button.export-images').click(function (ev) {
    // add paths[] fields
    var base_dir = $('#frm-images').data('folder');
    var base_el = $('#frm_export #paths');
    $('#frm_export input.paths').remove();
    $('#frm-images :checkbox:checked').each(function () {
      base_el.clone().
        removeAttr('id disabled').addClass('paths').
        val(base_dir + $(this).val()).
        insertAfter(base_el);
    });
    // toggle target buttons
    $('#frm_export').parent().toggleClass('is-hidden');
  });
    
  $('button.range_select').click(function () {
    $('button.range_select').toggleClass('is-light');
    $('.images .column.range_start').removeClass('range_start');
  });

  // manage click on linked image: area1 = select image, area2 = open link
  $('.images .column a').split_click({
    mode:  $('#frm-images').data('image-sel-mode'),
    area1: function (el, ev) {
      ev.preventDefault(); // do not open the link/zoom image
      
      // select the image
      el.siblings('.select-image').click();
      
      // animate selection
      if (el.siblings(':checkbox').prop('checked'))
        el.parent().addClass('clicked').
          find('figure').fadeTo(0,0).
          fadeTo(300, 1, function () { el.parent().removeClass('clicked'); });
      
      // range selection mode
      if ($('button.range_select').hasClass('is-light')) {
        if ($('.images .column.range_start').length == 0)
          el.parent().addClass('range_start'); // mark the first element of selection
        else {
          el.parent().addClass('range_end');
          var start = $('.images .column.range_start');
          // select all elements between the first element and this one
          var range = $('');
          if (start.nextAll('.range_end').length == 1) range = start.nextUntil('.range_end');
          if (start.prevAll('.range_end').length == 1) range = start.prevUntil('.range_end');
          range.each(function () {
            if ($(this).find(':checkbox:checked').length == 0)
              $(this).find('.select-image').click();
          });
          $('button.range_select').removeClass('is-light');
          el.parent().removeClass('range_end');
          $('.images .column.range_start').removeClass('range_start');
          console.log(range);
        }//if-else
      }//if
    }//area1
  });

  // set scoring
  $('.scoring span.icon[data-score]').click(function () {
    $('#score').val( $(this).data('score') );
    
    if ($(this).hasClass('clear-score')) // clear scoring status
      $('.scoring span.icon[data-score]:not(.clear-score)').removeClass('has-text-warning').find('i').text('star_outline');
    else { // change star color and filling
      $(this).prevAll('span.icon[data-score]').addBack().addClass('has-text-warning').find('i').text('star_rate');
      $(this).nextAll('span.icon[data-score]:not(.clear-score)').removeClass('has-text-warning').find('i').text('star_outline');
    }//if-else
    
    $('.scoring').after(p_bar);
    $(this).parents('form:first').submit();
  });

  // ehentai search callback: place titles in kanji/romaji/eng fields, and full text in notes field
  $('.ehentai-search').data('onselect', function (info) {
    $('#dest_title').val(info.title_jpn_clean || info.title_clean);
    $.myapp.append_to_textarea('#notes', info.title_jpn || info.title);
    
    if (info.title_eng) {
      $('#dest_title_eng').val(info.title_eng_clean);
      $.myapp.append_to_textarea('#notes', 'ENG: '+info.title_eng);
    }//if
    
    if (info.title_jpn) {
      $('#dest_title_romaji').val(info.title_clean);
      $.myapp.append_to_textarea('#notes', info.title);
    }//if
    
    $.myapp.autotag_titles();
    $.myapp.titles_to_lowercase();
  });

  // scroll tabs container to active tab (for mobile users)
  $('.tabs.is-boxed').scrollLeft( $('.tabs.is-boxed li.is-active').position().left );
}// if /process/edit


if ($('body').data('ctrl') +'/'+ $('body').data('action') == 'process/batch') {
  // js-finder search callback
  $('a.js-finder').data('onselect', function (info) {
    $('#options_doujin_id').val(info.id);
  });
}// if process/batch
// -----------------------------------------------------------------------------
}); })(jQuery)
