console.info('imported: application');

// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import 'libs/app-onload';

import 'controllers/common';

// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/import
switch ($q('body').attributes['data-ctrl'].textContent) {
  case 'process':   import('controllers/process');   break;
  case 'doujinshi': import('controllers/doujinshi'); break;
  case 'shelves':   import('controllers/shelves');   break;
  case 'authors':   import('controllers/metadata');  break;
  case 'circles':   import('controllers/metadata');  break;
  case 'themes':    import('controllers/metadata');  break;
}//switch
