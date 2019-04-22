$('.planting-facts').isotope({
  layoutMode: 'fitRows',
  percentPosition: true,
  itemSelector: '.fact',
  fitRows: {
    gutter: 10,
  }
});


$(document).ready(function() {
 $('#planting-timeline').roadmap(
     $('.planting-data').data('events'),
     {
      eventsPerSlide: 9,
      orientation: 'auto'
    }
  );
});