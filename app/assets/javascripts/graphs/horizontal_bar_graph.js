//= require d3
//= require graphs/bar_group
//= require graphs/bar_label_group

/*
Horizontal Bar Graph represents sum total of the graph including all of the parts:
Bars
Bar Labels

The main dimensions of the graph are rendered here.
 */

(function() {
  'use strict';

  var growstuff = (window.growstuff = window.growstuff || {});
  var BarGroup = growstuff.BarGroup;
  var BarLabelGroup = growstuff.BarLabelGroup;

  function HorizontalBarGraph(data) {
    this._data = data;
    this._d3 = d3;
  }

  HorizontalBarGraph.prototype.render = function(root) {
    var bars = this._data.bars;
    var width = this._data.width;
    var height = this._data.height;

    var margin = this._data.margin;

    var barLabelGroup = new BarLabelGroup(this._data);
    var margin = this._data.margin;

    var barGroup = new BarGroup(this._data);

    var svg = root
      .append("svg")
        .attr("width", width.size + margin.left + margin.right)
        .attr("height", height.size + margin.top + margin.bottom)
      .append("g")
        .attr("class","bar-graph")
        .attr("transform","translate(" + margin.left + "," + margin.top + ")");


    barGroup.render(svg);
    barLabelGroup.render(svg);

    return svg;
  };

  growstuff.HorizontalBarGraph = HorizontalBarGraph;
})();