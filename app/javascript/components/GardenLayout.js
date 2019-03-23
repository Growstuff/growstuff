import React from "react"
import PropTypes from "prop-types"

class GardenLayout extends React.Component {
  constructor(props) {
    super(props);
    // Don't call this.setState() here!
    this.state = {
      width: 5,
      height: 5,
      maxHeight: 25,
      maxWidth: 25
    };

    this.handleWidthChange = this.handleWidthChange.bind(this);
    this.handleHeightChange = this.handleHeightChange.bind(this);
  }
  createTable = () => {
    let table = []

    // Outer loop to create parent
    for (let x = 0; x < this.state.height; x++) {
      let children = []
      //Inner loop to create children
      for (let y = 0; y < this.state.width; y++) {
        children.push(
          <td>
            <GardenSquare x={x} y={y} key={`${x}_${y}`}/>
          </td>
        )
      }
      //Create the parent and add the children
      table.push(<tr>{children}</tr>)
    }
    return table
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

  render () {
    return (
      <React.Fragment>
        <p>
          <label>Width (max {this.state.maxWidth})</label>
          <input name="width" value={this.state.width}
            onChange={this.handleWidthChange}/>
          <label>Height (max {this.state.maxHeight})</label>
          <input name="height" value={this.state.height}
            onChange={this.handleHeightChange}/>
        </p>
        <table border="1">
          <tbody>
          {this.createTable()}
          </tbody>
        </table>
        Id: {this.props.id}
        Name: {this.props.name}
        Active: {this.props.active}
        Owner: {this.props.ownerId}
      </React.Fragment>
    );
  }
}

class GardenSquare extends React.Component {
  render() {
    return (
      <div className="card">
        <sub>{`${this.props.x + 1} x ${this.props.y + 1}`}</sub>
      </div>
    );
  }
}

GardenLayout.propTypes = {
  id: PropTypes.node,
  name: PropTypes.string,
  active: PropTypes.bool,
  ownerId: PropTypes.node
};
export default GardenLayout
