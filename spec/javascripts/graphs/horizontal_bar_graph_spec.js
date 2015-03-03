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
          bar_color: 'steelblue',
          width: {size: 300, scale: 'linear'},
          height: {size: 400, scale: 'ordinal'},
          //left is used to shift the bars over so that there is
          //room for the labels
          margin: {top: 0, right: 0, bottom: 0, left: 100}
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

      it('draws a group for the whole graph', function(){
        expect($('g.bar-graph')).toExist();
      });

      it('draws a bar group', function(){
        expect(BarGroup.prototype.render).toHaveBeenCalled();
      });

      it('draws a group of bar labels', function() {
        expect(BarLabelGroup.prototype.render).toHaveBeenCalled();
      });

      it('has the expected width and height', function() {
        var $svg = $('svg');
        var margin = data.margin;
        expect($svg).toHaveAttr('width', (data.width.size + margin.left + margin.right) + '');
        expect($svg).toHaveAttr('height', (data.height.size + margin.top + margin.bottom) + '');
      });

      it('draws the graph shifted to the right to accommodate for labels', function(){
        expect('g.bar-graph').toHaveAttr('transform', 'translate(100,0)');
      });

      it ('on the x axis, draws at least one bar at max width less margin width because of domain and range mapping', function(){
        expect('g.bar rect:eq(1)').toHaveAttr('width', '300' );
      });

      it ('on the y axis, all bars are the same height', function(){
        expect('g.bar rect:eq(0)').toHaveAttr('height', '195');
        expect('g.bar rect:eq(1)').toHaveAttr('height', '195');
      });

  });

})();
