(function(){
  'use strict';


  describe('BarGroup', function() {
  var BarGroup, subject;

  beforeEach(function() {
    BarGroup = growstuff.BarGroup;
    var bars = [
      {name: 'Shade', value: 0.2},
      {name: 'Half Shade', value: 0.5}
    ];
    var data = {
      bars:bars
    };
    subject = new BarGroup(data);
    subject.render(d3.select('#jasmine_content').append('svg'));
  })

  it('draws a group', function(){
    expect($('g.bar')).toExist()
  });

  it('draws 2 bars', function() {
    expect($('g.bar rect')).toHaveLength(2);
  });
});

})();