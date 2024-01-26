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
// = require leaflet.markercluster
// = require popper
// = require jquery
// = require jquery_ujs
// = require jquery-ui/widgets/autocomplete 
// = require bootstrap-sprockets
// = require bootstrap-datepicker
// = require bootstrap
// = require material
// = require_tree .

document.addEventListener("DOMContentLoaded", function (event) {
    // var dropdownTrigger = [].slice.call(document.querySelectorAll('[data-bs-toggle="dropdown"]')) 
    // var dropdownList = dropdownTrigger.map(function (dropdownTrigger2) { 
    //     return new bootstrap.Dropdown(dropdownTrigger2) 
    // });

    // var dropdownTrigger = [].slice.call(document.querySelectorAll('.dropdown-toggle')) 
    // var dropdownList = dropdownTrigger.map(function (dropdownTrigger2) { 
    //     return new bootstrap.Dropdown(dropdownTrigger2) 
    // });

    var popoverTrigger = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]')) 
    var popoverList = popoverTrigger.map(function (popoverTrigger2) { 
        return new bootstrap.Popover(popoverTrigger2) 
    });

    var tooltipTrigger = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]')) 
    var tooltipList = tooltipTrigger.map(function (tooltipTrigger2) { 
        return new bootstrap.Tooltip(tooltipTrigger2) 
    }); 
  });
