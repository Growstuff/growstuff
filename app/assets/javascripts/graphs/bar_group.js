//= require graphs/width_scale
//= require graphs/height_scale

(function(){
  'use strict';

  /*
  This represents bars for a bar graph.
  Currently these are used for HorizontalBarGraph.
   */

  var growstuff = (window.growstuff = window.growstuff || {});
  var WidthScale = growstuff.WidthScale;
  var HeightScale = growstuff.HeightScale;

function BarGroup(data) {
  this._data = data;
}

BarGroup.prototype.render = function(root){

  var data = this._data;
  var bars = this._data.bars;
  var widthScale = new WidthScale(data).render();
  var heightScale = new HeightScale(data).render();

  return root.append('g')
    .attr("class", "bar")
    .selectAll("rect")
    .data(bars.map(function(bar) { return bar.value; }))
    .enter()
    .append("rect")
    .attr("y", function(d, i){
      return heightScale(i);

    })
    .attr("height", heightScale.rangeBand())
    .attr("fill", data.bar_color)
    .attr("width", function(d){
      return widthScale(d);
    })
    .append("title")
    .text(function(d){
      return 'This value is ' + d + '.';
    });
};

BarGroup.prototype.getBarValues = function () {
  var barValues = [];
  var bars = this._data.bars;
  var i = 0;
  var data = this._data;

  for (i; i < data.bars.length; i++){
    barValues.push(data.bars[i].value)
  }

  return barValues;
};

growstuff.BarGroup = BarGroup;

}());