import React from "react"
import DataList from "../data/DataList";
import CropThumbnail from '../crops/CropThumbnail';

class Crops extends DataList {
  dataType = 'crops';
  title = 'Some of our crops';
    params() {
    return {
      'filter[interesting]' : true,
      'page[limit]': 4
    };
  }
  renderData() {
    return this.state.data.map((crop, index) => {
      return (
        <CropThumbnail key={index} crop={crop} />
      );
    });
  }
}
/*
%section.crops
  = cute_icon
  %h2= t('home.crops.our_crops')
  = render 'crops'
  = link_to "#{t('home.crops.view_all')} »", crops_path, class: 'btn btn-block'
*/
export default Crops
