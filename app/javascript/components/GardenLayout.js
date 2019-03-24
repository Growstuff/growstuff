import React from "react"
// import axios from 'axios';
import PlantingsList from './PlantingsList'
import GardenSquare from './GardenSquare'

class GardenLayout extends React.Component {
  constructor(props) {
    super(props);
    const width =3;
    const height = 3;
    const maxWidth = 20;
    const maxHeight = 20;

    this.state = {
      width: width,
      height: height,
      maxHeight: maxHeight,
      maxWidth: maxWidth,
      layout: this.initLayout(width, height),
      selected_planting_id: null
    };

    this.handleWidthChange = this.handleWidthChange.bind(this);
    this.handleHeightChange = this.handleHeightChange.bind(this);
    this.handlePlantingSelection = this.handlePlantingSelection.bind(this);
    this.handleLayoutAssignment = this.handleLayoutAssignment.bind(this);
    this.getLayoutPlanting = this.getLayoutPlanting.bind(this);
    this.initLayout = this.initLayout.bind(this);  }

  initLayout(width, height) {
    let layout = [];
    for (let x = 0; x < height; x++) {
      layout[x] = [];
      for (let y = 0; y < width; y++) {
        layout[x][y] = null;
      }
    }
    return layout;
  }

  renderTable = () => {
    let table = []

    // Outer loop to create parent
    for (let x = 0; x < this.state.height; x++) {
      let children = []
      //Inner loop to create children
      for (let y = 0; y < this.state.width; y++) {
        let planting_id = this.getLayoutPlanting(x, y);
        children.push(
          <td key={`${x}_${y}`}>
            <GardenSquare
              x={x}
              y={y}
              handleLayoutAssignment={this.handleLayoutAssignment}
              planting_id={planting_id}
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
  handleLayoutAssignment(x, y) {
    let layout = this.state.layout;
    layout[x][y] = this.state.selected_planting_id;
    this.setState({layout: layout});
    this.saveGardenLayout();
  }
  saveGardenLayout() {
    // API doesn't allow save ye
    // let data = {
    //     "data": {
    //       "type": "plantings",
    //       "id": this.props.garden.id,
    //       "attributes": {
    //         "layout": JSON.stringify(this.state.layout)
    //       }
    //     }
    // };
    // console.log(data);
    // axios.put('/api/v1/gardens', data)
    //   .then(function (response) {
    //     console.log(response);
    //   })
    //   .catch(function (error) {
    //     console.log(error);
    //   });
  }
  handlePlantingSelection(event) {
    this.setState({selected_planting_id: parseInt(event.target.value)});
  }

  getLayoutPlanting(x, y) {
    return this.state.layout[x][y];
  }

  render () {
    return (
      <React.Fragment>
        <div className="row">
          <label>Width (max {this.state.maxWidth})</label>
          <input name="width" type="number"
            size="3"
            min="0"
            value={this.state.width}
            onChange={this.handleWidthChange}/>
          <label>Height (max {this.state.maxHeight})</label>
          <input name="height" type="number"
            size="3"
            min="0"
            value={this.state.height}
            onChange={this.handleHeightChange}/>
        </div>
        <div className="row">
          <h3>Layout</h3>
          <p>Selected planting: {this.state.selected_planting_id}</p>
          <div className="col-sm-2">
            <PlantingsList
              garden_id={this.props.garden.id}
              handleSelection={this.handlePlantingSelection} />
          </div>
          <div className="col-sm-8">
            {this.renderTable()}
          </div>
          <div className="col-sm-2">
            {JSON.stringify(this.state.layout)}
          </div>
        </div>
      </React.Fragment>
    );
  }
}




export default GardenLayout;
