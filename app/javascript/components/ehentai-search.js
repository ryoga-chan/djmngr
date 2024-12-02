console.info('LOADING components/ehentai-search.js');

$(function () {
// -----------------------------------------------------------------------------
// search on term change
$('body').on('change', '#ehentai-search-modal .search-term', function () {
  var modal = $('#ehentai-search-modal'),
      input = modal.find('.search-term').blur(),
      list  = modal.find('.lookup-results'),
      term  = input.val().trim();
  
  if (term.length == 0)
    return;
  
  $.ajax({
    url: '/ws/ehentai',
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
            <div class="column is-4">
              <figure class="image is2by3">
                <img class="reference" src="${this.thumb || '/not-found.png'}" loading="lazy" decoding="async">
              </figure>
            </div>
            <div class="column left-border">
              <div class="mb-2 tag is-info">${this.filecount || '--'} P</div>
              <div class="mb-2 tag is-info">${(parseInt(this.filesize || 0) / 1024 / 1024).toFixed(2)} MiB</div>
              <div class="mb-2 tag is-info">${(this.posted || '-no date-').substr(0,10).replace('T',' ')}</div>
              <div class="mb-2 tag is-light ${this.gid ? '' : 'is-hidden'}">
                <a href="https://e-hentai.org/g/${this.gid}/${this.token}/" target="_blank">view</a>
              </div>
              <div class="mb-1 has-text-weight-bold">${this.title || this.error || '--'}</div>
              <div>${this.title_jpn || this.error || '--'}</div>
              <div class="is-italic">${this.title_eng}</div>
            </div>
          </div>
        `).appendTo(list).
         find('img').data('info', this).click(function () {
           modal.
             data('caller').
             data('onselect')( $(this).data('info') );
           $('#ehentai-search-modal button.delete').click();
         });
      });
    },//success
    complete: function () { input.parent().removeClass('is-loading'); },//complete
    error: function () { alert('Server error!'); }//error
  });
});

// open search dialog
$('body').on('click', '.ehentai-search', function (ev) {
  ev.preventDefault();
  
  var caller = $(this);
  var modal  = $('#ehentai-search-modal').data('caller', caller).addClass('is-active');
  // set cover source
  modal.find('img.reference').attr('src', $(caller.data('img')).attr('src'));
  modal.find('.orig_info' ).text( caller.data('info')  );
  modal.find('.orig_title').text( caller.data('title') );
  if (caller.data('title') != caller.data('title-kakasi'))
    modal.find('.orig_title_kakasi').text( caller.data('title-kakasi') );
  // set search term and run search
  modal.find('.search-term').val( caller.data('term') ).change();
});

// close search dialog
$('body').on('click',
  '#ehentai-search-modal button.delete, #ehentai-search-modal .modal-background',
  function (ev) {
    ev.preventDefault();
    
    var modal = $('#ehentai-search-modal').removeData('caller').removeClass('is-active');
    modal.find('img.reference').removeAttr('src');
    modal.find('.search-term').val('');
  });
// -----------------------------------------------------------------------------
});
