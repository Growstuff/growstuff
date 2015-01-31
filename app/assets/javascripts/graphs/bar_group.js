//= require graphs/graph_scale

(function(){
  'use strict';


  var growstuff = (window.growstuff = window.growstuff || {});
  var GraphScale = growstuff.GraphScale;

function BarGroup(data) {
  this._data = data;
}

BarGroup.prototype.render = function(root){

  var data = this._data;
  var bars = this._data.bars;
  var xScale = new GraphScale(data, 'width').render();
  var yScale = new GraphScale(data, 'height').render();

  return root.append('g')
    .attr("class", "bar")
    .selectAll("rect")
    .data(bars.map(function(bar) { return bar.value; }))
    .enter()
    .append("rect")
    .attr("y", function(d, i){
      return yScale(i);

    })
    .attr("height", yScale.rangeBand())
      .attr("fill", "steelblue")
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