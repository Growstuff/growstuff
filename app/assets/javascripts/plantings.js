// init Isotope
var $grid = $('.planting-facts').isotope({
  layoutMode: 'fitRows',
  percentPosition: true,
  itemSelector: '.fact',
  fitRows: {
    gutter: 10
  }
});
// layout Isotope after each image loads
// $grid.imagesLoaded().progress( function() {
//   $grid.isotope('layout');
// });

