(function(){
  'use strict';

  describe('GraphScale', function(){
    var data, GraphScale, subject;

    beforeEach(function(){
      GraphScale = growstuff.GraphScale;
      var bars = [
        {name: 'Shade', value: 0.2},
        {name: 'Half Shade', value: 0.5}
      ];
      data = {
        bars: bars,
        width: {size: 300, scale: 'linear'},
        height: {size: 400, scale: 'ordinal'}
      };
    });

    describe('when specifying width', function() {
      var mockD3;
      beforeEach(function() {
        subject = new GraphScale(data, 'width');
        mockD3 = jasmine.createSpyObj('d3', ['domain', 'range', 'max']);
        mockD3.domain.and.returnValue(mockD3);
        mockD3.range.and.returnValue(mockD3);
        spyOn(d3.scale, 'linear').and.returnValue(mockD3);
        subject.render();
      });
      it ('gets the values of all the bars', function(){
        expect(subject.getBarValues()).toEqual([0.2, 0.5]);
      });

      it ('calls the d3 range function to draw the width', function(){
        expect(mockD3.range).toHaveBeenCalledWith([0, 300]);
      });

    });

    describe('when specifying height', function() {
      var mockD3;
      beforeEach(function() {
        subject = new GraphScale(data, 'height');
        mockD3 = jasmine.createSpyObj('d3', ['domain', 'rangeRoundBands']);
        mockD3.domain.and.returnValue(mockD3);
        mockD3.rangeRoundBands.and.returnValue(mockD3);
        spyOn(d3.scale, 'ordinal').and.returnValue(mockD3);
        subject.render();
      });
      it ('calls the d3 range round bands function to draw the height', function(){
        expect(mockD3.rangeRoundBands).toHaveBeenCalledWith([0, 200], 0.05, 0);
      });
    });
  });

})();