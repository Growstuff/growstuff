// The little pencil beside a fact's label swaps that fact's value for a form.
// Both the value and the pencils go while the form is open, so nothing is left
// showing behind it.
$(document).ready(function() {
  $('.editable').click(function(event) {
    event.preventDefault();
    $(this.dataset.form).show();
    $(this.dataset.display).hide();
    $(this).closest('.fact-card').find('.edit-link').hide();
  });
});
