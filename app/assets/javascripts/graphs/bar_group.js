(function(){
  'use strict';

var growstuff = (window.growstuff = window.growstuff || {});

function BarGroup(bars) {
  this._bars = bars;
}

BarGroup.prototype.render = function(d3){
  var bars = this._bars;
  return d3.append('g')
    .attr("class", "bar")
    .selectAll("rect")
    .data(bars.map(function(bar) { return bar.value; }))
    .enter()
    .append("rect");
};

growstuff.BarGroup = BarGroup;


})();