// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import 'libs/jquery';                   // sets window.{jQuery, $}
import 'jquery-ujs';                    // sets window.{jQuery, $}.rails

import 'libs/hammer';                   // sets window.Hammer
import 'libs/hammer-jquery';
import 'libs/sortable-jquery';
import 'libs/freeze_frame-jquery';

import 'components/ehentai-search';
import 'components/img_ondemand_load';
import 'components/img_sequential_load';
import 'components/jQKeyboard';
import 'components/js-finder';
import 'components/js-tagger';
import 'components/split-click';

import 'libs/app';

import 'controllers/doujinshi';
import 'controllers/favorites';
import 'controllers/metadata';
import 'controllers/process';
import 'controllers/shelves';
