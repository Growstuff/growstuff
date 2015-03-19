(function(){
  'use strict';

  /*
  This file contains tests for the labels that get rendered next to each bar
   */

  describe('BarLabelGroup', function(){

    var BarLabelGroup, subject, data;

    beforeEach(function(){
      BarLabelGroup = growstuff.BarLabelGroup;
      var bars = [
        {name: 'Shade', value: 0.2},
        {name: 'Half Shade', value: 0.5}
      ];
      data = {
        bars: bars
      };
      subject = new BarLabelGroup(data);
      subject.render(d3.select('#jasmine_content').append('svg'));
    })

    it('draws a group for labels', function(){
      expect($('g.bar-label')).toExist()
    });

    it('draws 2 bar labels', function(){
      expect($('g.bar-label text')).toHaveLength(2);
    })

    it ('has text for 2 bar labels', function(){
      //jquery jasmine appends text from all text elements
      // into one string
      expect($('g.bar-label text')).toHaveText('ShadeHalf Shade');

    })

  });


})();