// The site's jQuery-era scripts expect these as globals, and jQuery plugins
// attach to window.jQuery, so globals must be set before anything else loads.
import './globals';

import 'jquery-ujs';
import 'jquery-ui/dist/jquery-ui';
import 'leaflet.markercluster';

import './site/auto_suggest';
import './site/cropmap';
import './site/editable';
import './site/finish_toggle';
import './site/job_ideas';
import './site/job_notepad';
import './site/likes';
import './site/members';
import './site/navbar_search';
import './site/places';
import './site/planting_alternate_name';
import './site/shareon';
import './site/tab_navigation';
import { initFlashMessages } from './site/flash_messages';

document.addEventListener('DOMContentLoaded', function() {
  initFlashMessages();
  var popoverTrigger = Array.prototype.slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'));
  popoverTrigger.map(function(popoverTrigger2) {
    return new bootstrap.Popover(popoverTrigger2);
  });

  var tooltipTrigger = Array.prototype.slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
  tooltipTrigger.map(function(tooltipTrigger2) {
    return new bootstrap.Tooltip(tooltipTrigger2);
  });
});

// Tell the server which time zone the browser is in, so "today" and "yesterday"
// are the member's own days.
try {
  document.cookie = 'timezone=' + encodeURIComponent(Intl.DateTimeFormat().resolvedOptions().timeZone) +
    '; path=/; max-age=31536000; SameSite=Lax';
} catch (error) {
  // No time zone to send: the server's is used.
}
