(function(){
  'use strict';

  describe('BarGroup', function() {
  var BarGroup, subject, xScale;

  beforeEach(function() {

    var GraphScale = growstuff.GraphScale;
    BarGroup = growstuff.BarGroup;

    var bars = [
      {name: 'Shade', value: 0.2},
      {name: 'Half Shade', value: 0.5}
    ];

    var data = {
      bars: bars,
      width: {size: 300, scale: 'linear'},
      height: {size: 400, scale: 'ordinal'}
    };


    xScale = new GraphScale(data, 'x');
    subject = new BarGroup(data);
    subject.render(d3.select('#jasmine_content').append('svg'));
  })

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




  });

})();