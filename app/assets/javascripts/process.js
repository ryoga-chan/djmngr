(function ($) { $(function () {
// -----------------------------------------------------------------------------
var p_bar = '<progress class="progress is-small is-info" max="100">i</progress>';


if ($('body').data('ctrl') +'/'+ $('body').data('action') == 'process/index') {
  // add page shortcuts
  $.myapp.shortcuts.push({ key: 'b', ctrl: false, alt: true, descr: 'toggle batch mode', action: function (ev) { $('a.bt-batch').get(0).click(); } });
  $.myapp.shortcuts.push({ key: 't', ctrl: false, alt: true, descr: 'toggle checked entries for batch', action: function (ev) { $('a.bt-toggle-all').get(0).click(); } });
  $.myapp.shortcuts.push({ key: 'r', ctrl: false, alt: true, descr: 'refresh entries index', action: function (ev) { $('a.bt-reindex').get(0).click(); } });
  
  $.app = $.extend($.app, {
    update_tot_filesize: function () {
      var tot_bytes = 0;
      $('.file-select :checkbox:checked').each(function(){ tot_bytes += $(this).data('size'); });
      $('span.tot-file-size').text(tot_bytes > 0 ? '(~'+(tot_bytes / 1024 / 1024).toFixed(0)+' MB)' : '');
    }//update_tot_filesize
  });
  
  // update total file size label
  $('.file-select').click($.app.update_tot_filesize);
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
  // add page shortcuts - tab move - copy title kanji/romaji/eng to filename
  $.myapp.shortcuts.push({ key: 'r', ctrl: false, alt: true, descr: 'copy kanji title to filename'  , action: function (ev) { $('#dest_filename').val( $('#dest_title'       ).val().trim() + '.zip' ); } });
  $.myapp.shortcuts.push({ key: 't', ctrl: false, alt: true, descr: 'copy romaji title to filename' , action: function (ev) { $('#dest_filename').val( $('#dest_title_romaji').val().trim() + '.zip' ); } });
  $.myapp.shortcuts.push({ key: 'e', ctrl: false, alt: true, descr: 'copy english title to filename', action: function (ev) { $('#dest_filename').val( $('#dest_title_eng'   ).val().trim() + '.zip' ); } });
  // add page shortcuts - scoring
  $.myapp.shortcuts.push({ key: '0', ctrl: false, alt: false, descr: 'clear scoring', action: function (ev) { $('span.clear-score').get(0).click(); } });
  for (let i = 1; i <= 10; i++)
    $.myapp.shortcuts.push({ key: i.toString(), ctrl: false, alt: false, descr: 'assign score 1', action: function (ev) { $('span.set-score[data-score="'+i+'"]').get(0).click(); } });
  // add page shortcuts - pics
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
  
  // select image when clicking on a specific half of it
  // and open the link on the other half
  $('.images .column a').click(function (ev) {
    var link = $(this);
    var is_select_area = false;
    
    // ev.offsetX      / ev.offsetY         => element relative coordinates
    // $(this).width() / $(this).height()   => element size
    var y_ratio = $(this).height() / $(this).width();
    switch (link.parents('form:first').data('image-sel-mode')) {
      case '\\': is_select_area = ev.offsetX > (ev.offsetY / y_ratio); break;
      case  '/': is_select_area = ev.offsetX > ($(this).width() - ev.offsetY / y_ratio); break;
      case  '|': is_select_area = ev.offsetX > $(this).width() /2; break;
      case  '-': is_select_area = ev.offsetY < $(this).height()/2; break;
    }//switch
    
    if (is_select_area) {
      ev.preventDefault(); // do not open the link/zoom image
      // select the image
      link.siblings('.select-image').click();
      // animate selection
      if (link.siblings(':checkbox').prop('checked'))
        link.
          parent().addClass('clicked').
          find('figure').fadeTo(0,0).fadeTo(300, 1, function () {
            link.parent().removeClass('clicked');
          });
    }//if
  });

  // update the single image name in "files" and "images"
  $('input[name="file_name"], input[name="img_name"]').change(function () {
    var el = $(this);
    
    $.ajax({
      url: el.data('url'),
      data: {
        name: el.val(),
        path: el.data('path')
      },
      method: 'POST',
      dataType: 'json',
      cache: false,
      beforeSend: function () { el.addClass('is-hidden').after(p_bar); },//beforeSend
      success: function (resp) {
        if (resp.result != 'ok')
          alert(resp.msg || 'Server error!');
      },//success
      complete: function () { el.removeClass('is-hidden').next().remove(); },//complete
      error: function () { alert('Server error!'); }//error
    });
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

  // scroll tabs container to active tab (for mobile users)
  $('.tabs.is-boxed').scrollLeft( $('.tabs.is-boxed li.is-active').position().left );  
}// if /process/edit
// -----------------------------------------------------------------------------
}); })(jQuery)
