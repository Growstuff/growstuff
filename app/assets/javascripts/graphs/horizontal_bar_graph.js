//= require d3
//= require graphs/bar_group
//= require graphs/bar_label_group

(function() {
  'use strict';

  var growstuff = (window.growstuff = window.growstuff || {});
  var BarGroup = growstuff.BarGroup;
  var BarLabelGroup = growstuff.BarLabelGroup;
  var GraphScale = growstuff.GraphScale;

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

    var xScale = new GraphScale(this._data,'linear');
    var yScale = new GraphScale(this._data, 'ordinal');

    var barGroup = new BarGroup(this._data, xScale.render());

    var svg = root
      .append("svg")
        .attr("width", width + margin.left + margin.right)
        .attr("height", height + margin.top + margin.bottom)
      .append("g")
        .attr("class","bar-graph")
        .attr("transform","translate(" + margin.left + "," + margin.top + ")");


    barGroup.render(svg);
    barLabelGroup.render(svg);

    return svg;
  };

  growstuff.HorizontalBarGraph = HorizontalBarGraph;
})();