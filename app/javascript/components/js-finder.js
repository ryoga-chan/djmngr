$(function () {
// -----------------------------------------------------------------------------
// search on term change
$('body').on('change', '#js-finder-modal .search-term', function () {
  var modal = $('#js-finder-modal'),
      input = modal.find('.search-term').blur(),
      list  = modal.find('.lookup-results'),
      term  = input.val().trim();
  
  if (term.length == 0)
    return;
  
  $.ajax({
    url: modal.data('caller').data('url'),
    data: { term: term },
    dataType: 'json',
    cache: false,
    beforeSend: function () {
      list.html('<progress class="progress is-small is-info" max="100">i</progress>');
      input.parent().addClass('is-loading');
    },//beforeSend
    success: function (resp) {
      list.empty();
      
      $.each(resp, function () {
        $(`
          <div class="columns is-mobile result">
            <div class="column is-4 has-text-centered">
              <figure class="image is2by3 ${this.thumb ? '' : 'is-hidden'}">
                <img class="reference" src="${this.thumb}" loading="lazy" decoding="async">
              </figure>
              <div class="tag is-info is-light ${this.thumb ? 'is-hidden' : ''}">no preview</div>
            </div>
            <div class="column left-border">
              <a href="#" class="button is-small is-light select-item">
                <span class="icon is-small">
                  <i class="mi mi-small">task_alt</i>
                </span>
                <span>select</span>
              </a>
              
              <a href="${this.link}" class="button is-small is-light ${this.link ? '' : 'is-hidden'}" target="_blank">
                <span class="icon is-small">
                  <i class="mi mi-small">visibility</i>
                </span>
                <span>view</span>
              </a>
              
              <div class="mb-2 mt-1 tag is-info ${this.tag  ? '' : 'is-hidden'}">${this.tag }</div>
              <div class="mb-2 mt-1 tag is-info ${this.tag2 ? '' : 'is-hidden'}">${this.tag2}</div>
              <div class="mb-1 has-text-weight-bold ${this.descr ? '' : 'is-hidden'}">${this.descr}</div>
              <div class="is-italic ${this.descr2 ? '' : 'is-hidden'}">${this.descr2}</div>
            </div>
          </div>
        `).appendTo(list).
         find('a.select-item').data('info', this).click(function () {
           modal.
             data('caller').
             data('onselect')( $(this).data('info') );
           $('#js-finder-modal button.delete').click();
         });
      });//each
      
      list.freeze_frame();
    },//success
    complete: function () { input.parent().removeClass('is-loading'); },//complete
    error: function () { alert('Server error!'); }//error
  });
});

// open search dialog
$('body').on('click', '.js-finder', function (ev) {
  ev.preventDefault();
  
  var caller = $(this);
  var modal  = $('#js-finder-modal').data('caller', caller).addClass('is-active');
  // set an eventual default search term
  modal.find('.search-term').val( caller.data('term') ).focus();
  // run search if term is present
  if (caller.data('term') && caller.data('term').trim().length > 0)
    modal.find('.search-term').change();
});

// close search dialog
$('body').on('click',
  '#js-finder-modal button.delete, #js-finder-modal .modal-background',
  function (ev) {
    ev.preventDefault();
    
    var modal = $('#js-finder-modal').removeData('caller').removeClass('is-active');
    modal.find('.search-term').val('');
    modal.find('.lookup-results').empty();
  });
// -----------------------------------------------------------------------------
});
