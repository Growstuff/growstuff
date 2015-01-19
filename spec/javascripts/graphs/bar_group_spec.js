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
    var axis = {
      x: {attr_name: 'width', scale: 'linear'},
      y: {attr_name: 'height', scale: 'ordinal'}
    };
    var data = {
      bars: bars,
      axis: axis
    };


    xScale = new GraphScale(data, 'linear');
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
    expect($('g.bar rect')).toHaveAttr('fill', 'rebeccapurple');
  });

  it ('gets the values of all the bars', function(){
    expect(subject.getBarValues()).toEqual([0.2, 0.5]);
  });




  });

})();