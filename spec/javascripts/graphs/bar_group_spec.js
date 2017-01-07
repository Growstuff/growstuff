(function(){
  'use strict';

  /*
  These tests are for the BarGroup object.
   */

  describe('when drawing the group of bars', function() {
  var BarGroup, subject, widthScale, bars, data;

  beforeEach(function() {

    var WidthScale = growstuff.WidthScale;
    BarGroup = growstuff.BarGroup;

    bars = [
      {name: 'Shade', value: 0.2},
      {name: 'Half Shade', value: 0.5}
    ];

    data = {
      bars: bars,
      bar_color: 'steelblue',
      width: {size: 300, scale: 'linear'},
      height: {size: 400, scale: 'ordinal'}
    };

    widthScale = new WidthScale(data);
    subject = new BarGroup(data);
    subject.render(d3.select('#jasmine_content').append('svg'));
  });

    it('draws a group', function(){
      expect($('g.bar')).toExist()
    });

    it('draws 2 bars', function() {
      expect($('g.bar rect')).toHaveLength(2);
    });

    it('fills the bars with color', function(){
      expect($('g.bar rect')).toHaveAttr('fill', 'steelblue');
    });

    it ('gets the values of all the bars', function(){
      expect(subject.getBarValues()).toEqual([0.2, 0.5]);
    });

    it('shows a tooltip on hover', function(){
      var i;

      //get all of the title nodes for the bars
      var barNodes = $('g.bar rect title');

      for (i = 0; i < bars.length; i++){
        //this is ugly but how jquery wants to access this list of titles
        expect($(barNodes[i]).html())
            .toBe(('title', 'This value is ' + bars[i].value + '' + '.'));
      }
    });


  });

}());