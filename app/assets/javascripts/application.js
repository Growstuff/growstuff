// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
// = require leaflet
// = require leaflet.markercluster/dist/leaflet.markercluster
// = require popper
// = require jquery
// = require jquery_ujs
// = require jquery-ui/widgets/autocomplete
// = require bootstrap-sprockets
// = require bootstrap-datepicker
// = require_tree .

document.addEventListener('DOMContentLoaded', function(event) {
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
