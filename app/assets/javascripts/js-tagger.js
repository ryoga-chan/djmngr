/*
TAGGER
----------------------------------------
  .js-tagger{data: {title: "Add tags", url: url_for(controller: :name, action: :tags_lookup) }}
      %button.button.is-rounded.is-small.mr-2.js-tagger-search
        %span.icon.is-small
          %i.mi.mi-small add
        %span tag
    
    .field.is-grouped.is-grouped-multiline.js-tagger-list
      - rel = rel.to_a.unshift Model.new id: :RECORD_ID, label_field: :LABEL # new recor for template item
      - rel.each do |r|
        .control{class: ('js-tagger-template is-hidden' if r.new_record?)}
          = hidden_field_tag "record[relation_ids][]", r.id_before_type_cast, id: nil
          .tags.has-addons
            %span.tag.is-link.is-light
              = link_to r.label_field,
                {controller: :name, action: :show, id: r.id_before_type_cast},
                target: :_blank
            %a.tag.is-delete{href: "model-#{r.id_before_type_cast}"}

MODAL DIALOG
----------------------------------------
  #js-tagger-modal.modal
    .modal-background
    .modal-card(style="height: calc(100vh - 40px)")
      %header.modal-card-head
        %p.modal-card-title Add tags
        %button.delete.js-tagger-cancel
      %section.modal-card-body
        .columns
          .column.is-half
            .field.is-grouped.is-grouped-multiline.current-tags
          .column.is-half.search-area(style="border-left: 1px solid silver")
            .control.has-icons-left
              %input.input.is-rounded.js-tagger-term{type: :text, placeholder: :search}
              %span.icon.is-small.is-left
                %i.mi.mi-small search
              %nav.panel.lookup-results
      %footer.modal-card-foot
        %button.button.is-success.js-tagger-set Set
        %button.button.js-tagger-cancel Cancel
*/
(function ($) { $(function () {
// -----------------------------------------------------------------------------
// save template in memory and remove it from DOM
$('.js-tagger').each(function () {
  var html = $(this).find('.js-tagger-template').detach().
    removeClass('is-hidden js-tagger-template').get(0).outerHTML;
  $(this).data('html-template', html);
});

// remove a tag
$('body').on('click', '.js-tagger a.tag.is-delete, #js-tagger-modal .current-tags', function (ev) {
  ev.preventDefault();
  var parent = $(ev.target).parents('.control:first');
  parent.fadeOut(function () { parent.remove(); });
});

// open search dialog
$('body').on('click', '.js-tagger .js-tagger-search', function (ev) {
  ev.preventDefault();
  
  var tagger = $(ev.target).parents('.js-tagger:first');
  $('#js-tagger-modal').
    data('tagger', tagger).addClass('is-active').
    find('.current-tags').html( tagger.find('.js-tagger-list').html() ).end().
    find('.modal-card-title').html( tagger.data('title') ).end().
    find('.js-tagger-term').focus();
});

// close search dialog
$('body').on('click', '#js-tagger-modal .js-tagger-cancel, #js-tagger-modal .modal-background', function (ev) {
  ev.preventDefault();
  $('#js-tagger-modal').removeData('tagger').removeClass('is-active').
    find('.current-tags, .lookup-results').empty().end().
    find('.js-tagger-term').val('');
});

// copy tags list from modal to tagger
$('body').on('click', '#js-tagger-modal .js-tagger-set', function (ev) {
  ev.preventDefault();
  
  var modal  = $('#js-tagger-modal'),
      tagger = modal.data('tagger');
  tagger.find('.js-tagger-list').html( modal.find('.current-tags').html() );
  
  $('#js-tagger-modal .js-tagger-cancel').click();
});

// add tag from results
$('body').on('click', '#js-tagger-modal .lookup-results a', function (ev) {
  ev.preventDefault();
  
  var modal  = $('#js-tagger-modal'),
      tagger = modal.data('tagger')
      result_tag = $(this);
  
  // prevent another click while fading the tag
  if (result_tag.data('clicked'))
    return;
  result_tag.data('clicked', true);
  
  var html = tagger.data('html-template').
    replace(/RECORD_ID/g, result_tag.data('id' )).
    replace(/LABEL/g    , result_tag.data('lbl'));
  
  // append new tag to curren list
  modal.find('.current-tags').prepend(html);
  // remove tag from results
  result_tag.fadeOut(function () { result_tag.remove(); });
});

// bind event to "search by term" field
$('body').on('keydown', '#js-tagger-modal .js-tagger-term', function (ev) {
  var modal  = $('#js-tagger-modal'),
      tagger = modal.data('tagger'),
      input  = modal.find('.js-tagger-term'),
      list   = input.siblings('.lookup-results');
  
  //console.log(ev.which);
  
  if (ev.which == 37 || ev.which == 39)     // left, right - NOOP
    return;
  
  if (ev.which == 27) {   // ESC - close dialog
    $('#js-tagger-modal .js-tagger-cancel').click();
    return;
  }//if
  
  if (ev.which == 38 || ev.which == 40) {   // up, down - select result
    ev.preventDefault();
    
    var cur_item = list.find('.is-active');
    
    if (cur_item.length > 0) {
      if (ev.which == 40) { // down
        if (cur_item.next().length > 0)
          cur_item.next().addBack().toggleClass('is-active');
      } else // up
        if (cur_item.prev().length > 0)
          cur_item.prev().addBack().toggleClass('is-active');
    } else
      list.find('a:first').addClass('is-active');
    
    return;
  }//if
  
  if (ev.which == 13) {   // return - add current selected item
    list.find('.is-active').click();
    return;
  }//if
  
  // stop previous delayed search
  clearTimeout(modal.data('timeout-id'));
  
  // plan delayed search
  var timeout_id = setTimeout(function () {
    var term  = input.val().trim();
    
    // don't search the same term again
    if (input.data('prev-term') == term)
      return;
    input.data('prev-term', term);
    
    $.ajax({
      url: tagger.data('url'),
      data: { term: input.val().trim() },
      dataType: 'json',
      cache: false,
      beforeSend: function () {
        list.empty();
        input.parent().addClass('is-loading');
      },//beforeSend
      success: function (resp) {
        if (resp.result != 'ok') {
          alert(resp.msg || 'Server error!');
          return;
        }//if
        
        // fill list below input
        var used_ids = $('.current-tags input').
          map(function () { return parseInt($(this).val()); }).get();
        $.each(resp.tags, function () {
          if ($.inArray(parseInt(this.id), used_ids) == -1) // append only unused tags
            $('<a class="panel-block"></a>').
              text(this.label).
              append('<tt style="position: absolute; right: 0;">🆔'+this.id+'</tt>').
              attr('data-id', this.id).attr('data-lbl', this.label).
              appendTo(list);
        });
      },//success
      complete: function () { input.parent().removeClass('is-loading'); },//complete
      error: function () { alert('Server error!'); }//error
    });
  }, 1000);
  modal.data('timeout-id', timeout_id);
});
// -----------------------------------------------------------------------------
}); })(jQuery)
