import React from "react"
import PropTypes from "prop-types"
class Garden extends React.Component {
  render () {
    return (
      <React.Fragment>
        Id: {this.props.id}
        Name: {this.props.name}
        Active: {this.props.active}
        Owner: {this.props.ownerId}
      </React.Fragment>
    );
  }
}

Garden.propTypes = {
  id: PropTypes.node,
  name: PropTypes.string,
  active: PropTypes.bool,
  ownerId: PropTypes.node
};
export default Garden
