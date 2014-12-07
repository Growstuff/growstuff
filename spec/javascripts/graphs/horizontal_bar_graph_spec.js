(function(){
  'use strict';


    describe('HorizontalBarGraph', function() {
      var BarLabelGroup, BarGroup, subject, data;
    beforeEach(function() {
      var HorizontalBarGraph = growstuff.HorizontalBarGraph;
      var bars = [
        {name: 'Shade', value: 0.2},
        {name: 'Half Shade', value: 0.5}
      ];
      data = {
        bars: bars,
        width: 300,
        height: 400,
        margin: {top: 30, right: 0, bottom: 0, left: 100}
      };
      subject = new HorizontalBarGraph(data);
      BarGroup = growstuff.BarGroup;
      BarLabelGroup = growstuff.BarLabelGroup;
      expect(BarLabelGroup).toExist();
      spyOn(BarGroup.prototype, 'render').and.callThrough();
      spyOn(BarLabelGroup.prototype, 'render').and.callThrough();
      subject.render(d3.select($('#jasmine_content')[0]));
    });

    it('draws a graph', function() {
      expect($('#jasmine_content svg')).toExist();
    });

    it('draws a bar group', function(){
      expect(BarGroup.prototype.render).toHaveBeenCalled();
    });

    it('draws a group of bar labels', function() {
      expect(BarLabelGroup.prototype.render).toHaveBeenCalled();
    });

    it('has the expected with and height', function() {
      var $svg = $('svg');
      var margin = data.margin;
      expect($svg).toHaveAttr('width', (data.width + margin.left + margin.right) + '');
      expect($svg).toHaveAttr('height', (data.height + margin.top + margin.bottom) + '');
    });
  });

})();
