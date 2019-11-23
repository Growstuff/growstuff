import React from "react"
import PropTypes from "prop-types"
class CropThumbnail extends React.Component {
  photoUrl() {
    return this.props.crop.attributes.thumbnail;
  }
  renderImage() {
    if (this.photoUrl()) {
      return (
        <img src={this.photoUrl()} className="img img-card" alt={this.props.crop.name} />
      );
    }
    else {
      return '';
    }
  }
  render () {
    let crop = this.props.crop.attributes;
    console.log(crop);
    let crop_url = `/crops/${crop.slug}`;
    return (
      <div className="card crop-thumbnail">
        <a href={crop_url}>
          {this.renderImage()}
          <div className="text">
            <h3>{crop.name}</h3>
            <h5 className="crop-sci-name">{crop['default-scientific-name']}</h5>
          </div>
        </a>
      </div>
    );
  }
}

export default CropThumbnail;
