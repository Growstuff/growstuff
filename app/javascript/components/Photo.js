import React from "react";
import PropTypes from "prop-types";
import axios from 'axios';

import { Formik, Form, Field, ErrorMessage } from 'formik';


class Photo extends React.Component {
  constructor(props) {
    super(props);
    this.handleEditClick = this.handleEditClick.bind(this);
    this.handleSave = this.handleSave.bind(this);
    this.state = { editable: false, title: this.props.title, hovering: false };
  }
  handleEditClick() {
  	this.setState({editable: true});
  }

  conn() {
    return axios.create({
      timeout: 1000,
      headers:{'content-type': 'application/vnd.api+json' }
    });
  }

  handleSave(values) {
  	let data = {
      "type": "photos",
      "id": this.props.id,
      "attributes": {title: values['title']}
      };

  	console.log(data);

	   this.conn().patch(`/api/v1/photos/` + this.props.id, {data: data})
      .then((res) => this.setState({
          editable: false, title: values['title']
        })
      )
      .catch((res) => this.setState({
          loading: false, data: [], hasError: true, errors: res.response.data.errors
        })
      );

    this.setState({editable: false});
  }
  render () {
    return (
      <React.Fragment>
        {!this.state.editable && 
  		    <h1 onClick={this.handleEditClick}>
  			    {this.state.title}
  			  {this.props.canEdit && <a className="btn-sm" onClick={this.handleEditClick}><i className="fas fa-pencil-alt"></i>edit</a> }
		      </h1>
    	 }
        {this.state.editable &&
          <h1>{this.renderForm()}</h1>
        }
      </React.Fragment>
    );
  }

  renderForm() {
  	return (
	  <div>
	    <Formik
	      initialValues={{ title: this.state.title }}
	      validate={values => {
	        const errors = {};
	        if (!values.title) {
	          errors.title = 'Required';
	        }
	        return errors;
	      }}
	      onSubmit={this.handleSave}
	    >
	      {({ isSubmitting }) => (
	        <Form>
	          <Field type="text" name="title" />
	          <ErrorMessage name="title" component="div" />
	          <button type="submit" className="btn btn-info" disabled={isSubmitting}>
	            save
	          </button>
	        </Form>
	      )}
	    </Formik>
	  </div>
	);
  }
}

        

const PhotoForm = () => 

Photo.propTypes = {
  title: PropTypes.string
};
export default Photo
