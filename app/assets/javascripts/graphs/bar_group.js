(function(){
  'use strict';

var growstuff = (window.growstuff = window.growstuff || {});

function BarGroup(data, xScale) {
  this._data = data;
  this._xScale = xScale;
}

BarGroup.prototype.render = function(root){

  var bars = this._data.bars;
  var xScale = this._xScale;
  console.log(xScale);
  return root.append('g')
    .attr("class", "bar")
    .selectAll("rect")
    .data(bars.map(function(bar) { return bar.value; }))
    .enter()
    .append("rect")
      .attr("fill", "rebeccapurple")
      .attr("width", function(d){
        return xScale(d);
      });
};

BarGroup.prototype.getBarValues = function () {
  var barValues = [];
  var bars = this._data.bars;
  var i = 0;
  var data = this._data;

  for (i; i < data.bars.length; i++){
    barValues.push(data.bars[i].value)
  };

  return barValues;
  }

growstuff.BarGroup = BarGroup;


})();