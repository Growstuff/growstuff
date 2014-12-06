//= require d3
//= require graphs/bar_group
//= require graphs/bar_label_group

(function() {
  'use strict';

  var growstuff = (window.growstuff = window.growstuff || {});
  var BarGroup = growstuff.BarGroup;
  var BarLabelGroup = growstuff.BarLabelGroup;

  function HorizontalBarGraph(data) {
    this._data = data;
  }

  HorizontalBarGraph.prototype.render = function(d3) {
    var bars = this._data.bars;
    var width = this._data.width;
    var height = this._data.height;
    var margin = this._data.margin;
    var barGroup = new BarGroup(bars);
    var barLabelGroup = new BarLabelGroup(data);
    var margin = this._data.margin;
    var svg = d3
      .append("svg")
      .attr("width", width + margin.left + margin.right)
      .attr("height", height + margin.top + margin.bottom);
    barGroup.render(svg);
    barLabelGroup.render(svg);
    return svg;
  };

  growstuff.HorizontalBarGraph = HorizontalBarGraph;
})();