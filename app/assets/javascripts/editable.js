$(document).ready(function() {
  $('.editable').click(function() {
    $(this.dataset.form).show();
    $(this.dataset.display).hide();
  });
});
