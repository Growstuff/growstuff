(function(){
  'use strict';

  describe('GraphScale', function(){
    var GraphScale, subject;

    beforeEach(function(){
      GraphScale = growstuff.GraphScale;
      var bars = [
        {name: 'Shade', value: 0.2},
        {name: 'Half Shade', value: 0.5}
      ];
      var axis = {
        x: {attr_name: 'width', scale: 'linear'},
        y: {attr_name: 'height', scale: 'ordinal'}
      };
      var data = {
        bars: bars,
        axis: axis
      };


      subject = new GraphScale(data, 'x');
      subject.render(d3.select('#jasmine_content').append('svg'));
    });


    it ('gets the values of all the bars', function(){
      expect(subject.getBarValues()).toEqual([0.2, 0.5]);
    });

  });

})();