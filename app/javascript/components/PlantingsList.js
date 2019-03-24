import React from "react"

class PlantingsList extends React.Component {
  render() {
    return (
      <div className="card">
        {this.renderPlantingsList()}
      </div>
    );
  }
  renderPlantingsList() {
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

export default PlantingsList;
