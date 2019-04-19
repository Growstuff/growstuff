// init Isotope
var $grid = $('.photos-grid').isotope({
  percentPosition: true,
  masonry: {
    columnWidth: '.photo-grid-sizer'
  }
  itemSelector: '.photo-grid-item'
});
