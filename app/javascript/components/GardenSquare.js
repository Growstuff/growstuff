import React from "react"

class GardenSquare extends React.Component {
  constructor(props) {
    super(props);
    this.state = {isLoaded: true};
    this.handleClick = this.handleClick.bind(this);
  }
  handleClick(event) {
    this.props.handleLayoutAssignment(this.props.x, this.props.y);
  }
  renderPlanting() {
    if(this.state.planting) {
      let planting = this.state.planting.attributes;
      return (
        <span>
          <img src={planting['thumbnail']} height="50" />
          <p> {planting['crop-name']} </p>
        </span>
        );
    }
  }
  render() {
    return (
      <div className="card">
        {!this.state.planting &&
          <button onClick={this.handleClick}><i className="fas fa-plus"></i></button>
        }
        {this.renderPlanting()}
      </div>
    );
  }

  componentDidUpdate(prevProps) {
    if(this.props.planting_id == null)
      return
    if (this.props.planting_id !== prevProps.planting_id) {
      this.fetchPlanting();
    }
  }

  fetchPlanting() {
    const url = `/api/v1/plantings/${this.props.planting_id}?included=[crop]`;
    fetch(url)
      .then(res => res.json())
      .then(
        (result) => {
          this.setState({
            isLoaded: true,
            planting: result.data
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
export default GardenSquare;
