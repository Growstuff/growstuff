(function() {
  'use strict';



  var growstuff = (window.growstuff = window.growstuff || {});

  function BarLabelGroup(data) {
    this._data = data;
  }

  BarLabelGroup.prototype.render = function(d3){
    var bars = this._data.bars;
    return d3.append('g')
      .attr("class", "bar-label")
      .selectAll("text")
      .data(bars.map(function(bar){ return bar.name;}))
      .enter()
      .append("text")
      .text(function(d) {return d});

  };

  growstuff.BarLabelGroup = BarLabelGroup;

})();