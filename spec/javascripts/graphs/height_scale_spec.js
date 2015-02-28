(function(){
  'use strict';

  describe('HeightScale when specifying height', function() {
    var data, bars, HeightScale, subject, mockD3;

    beforeEach(function(){
      HeightScale = growstuff.HeightScale;
      bars = [
        {name: 'Shade', value: 0.2},
        {name: 'Half Shade', value: 0.5}
      ];
      data = {
        bars: bars,
        width: {size: 300, scale: 'linear'},
        height: {size: 400, scale: 'ordinal'}
      };

      subject = new HeightScale(data);
      mockD3 = jasmine.createSpyObj('d3', ['domain', 'rangeRoundBands']);
      mockD3.domain.and.returnValue(mockD3);
      mockD3.rangeRoundBands.and.returnValue(mockD3);
      spyOn(d3.scale, 'ordinal').and.returnValue(mockD3);
      subject.render();

    });

    it('calls the d3 range round bands function to draw the height', function(){
      expect(mockD3.rangeRoundBands).toHaveBeenCalledWith([0, 400], 0.05, 0);
    });
  });

})();