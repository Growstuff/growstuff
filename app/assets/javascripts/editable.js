$(document).ready(function() {
  $('.editable').click(function() {
    $(this.dataset.form).modal('show');
  });

  $('.editable-date').click(function() {
    $(this.dataset.field).show();
    $(this.dataset.display).hide();
  });
});