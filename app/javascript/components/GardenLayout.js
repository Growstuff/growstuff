import React from "react"
import PropTypes from "prop-types"

class GardenLayout extends React.Component {
  constructor(props) {
    super(props);
    const width =3;
    const height = 3;

    let layout = [];
    for (let x = 0; x < height; x++) {
      layout[x] = [];
      for (let y = 0; y < width; y++) {
        layout[x][y] = null;
      }
    }

    this.state = {
      width: width,
      height: height,
      maxHeight: 20,
      maxWidth: 20,
      layout: layout,
      selected_planting_id: null
    };

    this.handleWidthChange = this.handleWidthChange.bind(this);
    this.handleHeightChange = this.handleHeightChange.bind(this);
    this.handlePlantingSelection = this.handlePlantingSelection.bind(this);
  }

  renderTable = () => {
    let table = []

    // Outer loop to create parent
    for (let x = 0; x < this.state.height; x++) {
      let children = []
      //Inner loop to create children
      for (let y = 0; y < this.state.width; y++) {
        children.push(
          <td key={`${x}_${y}`}>
            <GardenSquare
              x={x} y={y}
              />
          </td>
        )
      }
      //Create the parent and add the children
      table.push(<tr>{children}</tr>)
    }
    return (
      <table border="1">
        <tbody>
          {table}
        </tbody>
      </table>
      );
  }

  handleWidthChange(event) {
    let width = event.target.value;
    if (width > this.state.maxWidth) {
      width = this.state.maxWidth;
    }
    this.setState({width: width});
  }

  handleHeightChange(event) {
    let height = event.target.value;
    if (height > this.state.maxHeight) {
      height = this.state.maxHeight;
    }
    this.setState({height: height});
  }
  handlePlantingSelection(event) {
    this.setState({selected_planting_id: event.target.value});
  }
  getLayoutPlanting(x, y) {
    return this.state.layout[x][x];
  }

  render () {
    return (
      <React.Fragment>
        <div className="row">
          <label>Width (max {this.state.maxWidth})</label>
          <input name="width" value={this.state.width}
            onChange={this.handleWidthChange}/>
          <label>Height (max {this.state.maxHeight})</label>
          <input name="height" value={this.state.height}
            onChange={this.handleHeightChange}/>
        </div>
        <div className="row">
          <h3>Layout</h3>
          <p>Selected planting: {this.state.selected_planting_id}</p>
          <div className="col-sm-2">
            <PlantingsList garden_id={this.props.garden.id} handleSelection={this.handlePlantingSelection} />
          </div>
          <div className="col-sm-10">
            {this.renderTable()}
          </div>
        </div>
      </React.Fragment>
    );
  }
}


class PlantingsList extends React.Component {
  render() {
    return (
      <div className="card">
        {this.renderPlantingsList()}
      </div>
    );
  }
  renderPlantingsList() {
    console.log(this.state.plantings);
    return this.state.plantings.map((planting) =>
      <li key={planting.id}>
        <label>
          {planting.attributes['crop-name']}
          <input name="planting"
            type="radio"
            value={planting.id}
            onClick={this.props.handleSelection} />
        </label>
      </li>
    );
  }
  constructor(props) {
    super(props);

    this.state = {
      isLoaded: false,
      plantings: []
    };
  }

  componentDidMount() {
    const url = `/api/v1/gardens/${this.props.garden_id}/plantings`;
    console.log(url);
    fetch(url)
      .then(res => res.json())
      .then(
        (result) => {
          this.setState({
            isLoaded: true,
            plantings: result.data
          });
        },
        // Note: it's important to handle errors here
        // instead of a catch() block so that we don't swallow
        // exceptions from actual bugs in components.
        (error) => {
          this.setState({
            isLoaded: true,
            error
          });
        }
      )
  }
}

class GardenSquare extends React.Component {
  render() {
    return (
      <div className="card">
        <sub>
          {`${this.props.x + 1} x ${this.props.y + 1}`}
        </sub>
      </div>
    );
  }
}

export default GardenLayout
