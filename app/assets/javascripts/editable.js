$(document).ready(function() {
  $('.editable').click(function() {
    var modal = $(this.dataset.form);
    modal.modal('show');
    // $(this).hide()
  });
});