import React from "react"
import PropTypes from "prop-types"
class Seeds extends React.Component {
  dataType = 'seeds';
  render () {
    return (
      <section className="seeds">
        <h2>Seeds available to trade</h2>
      </section>
    );
  }
}

/*
%section.seeds
  = cute_icon
  = render 'seeds'
  %p.text-right= link_to "#{t('home.seeds.view_all')} »", seeds_path, class: 'btn btn-block'
  */

export default Seeds
