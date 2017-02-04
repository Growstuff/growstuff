(function(){
  'use strict';

  /*
  This file contains tests for the mapping the data values to
  the length of a bar so that it is the correct size for the screen
   */

  describe('GraphScale, when specifying width', function(){
    var data, WidthScale, subject, mockD3;

    beforeEach(function(){
      WidthScale = growstuff.WidthScale;
      var bars = [
        {name: 'Shade', value: 0.2},
        {name: 'Half Shade', value: 0.5}
      ];
      data = {
        bars: bars,
        width: {size: 300, scale: 'linear'},
        height: {size: 400, scale: 'ordinal'}
      };

      subject = new WidthScale(data, 'width');
      mockD3 = jasmine.createSpyObj('d3', ['domain', 'range', 'max']);
      mockD3.domain.and.returnValue(mockD3);
      mockD3.range.and.returnValue(mockD3);
      spyOn(d3.scale, 'linear').and.returnValue(mockD3);
      subject.render();
      });

      it ('gets the value of the longest bar', function(){
        expect(subject.getMaxValue()).toEqual(0.5);
      });

      it ('calls the d3 range function to draw the width', function(){
        expect(mockD3.range).toHaveBeenCalledWith([0, 300]);
      });
  });

}());
