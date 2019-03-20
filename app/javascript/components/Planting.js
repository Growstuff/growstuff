import React from "react"
import PropTypes from "prop-types"
class Planting extends React.Component {
  render () {
    return (
      <React.Fragment>
        Id: {this.props.id}
        Finished: {this.props.finished}
        Owner: {this.props.ownerId}
        Crop: {this.props.cropId}
      </React.Fragment>
    );
  }
}

Planting.propTypes = {
  id: PropTypes.node,
  finished: PropTypes.bool,
  ownerId: PropTypes.node,
  cropId: PropTypes.node
};
export default Planting
