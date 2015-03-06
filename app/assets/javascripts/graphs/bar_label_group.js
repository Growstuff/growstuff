(function() {
  'use strict';

/*
This file draws the labels to the left of each bar.
 */

  var growstuff = (window.growstuff = window.growstuff || {});

  function BarLabelGroup(data) {
    this._data = data;
  }

  BarLabelGroup.prototype.render = function(d3){
    var bars = this._data.bars;
    //vvcopy pasta from spike vv  -- this is a good candidate for refactor
    var barHeight = 40;

    return d3.append('g')
      .attr("class", "bar-label")
      .selectAll("text")
      .data(bars.map(function(bar){ return bar.name;}))
      .enter()
      .append("text")
      .attr('x', -80)
      .attr('y', function(d, i){
        //shrink the margin between each label to give them an even spread with
        //bars
        var barLabelSpread = 2/3;
        //move them downward to line up with bars
        var barLabelTopEdge = 17;
        return i * barHeight * (barLabelSpread) + barLabelTopEdge;
      })
      .text(function(d){return d});

  };

  growstuff.BarLabelGroup = BarLabelGroup;

})();