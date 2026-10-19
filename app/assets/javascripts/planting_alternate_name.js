// When a crop is chosen in the planting form, offer that crop's alternate names.
// Searching by an alternate name ("lauki") preselects it.
jQuery(function () {
  const wrapper = $('#planting-alternate-name');
  if (!wrapper.length) return;

  const select = wrapper.find('select');
  const cropId = $('#planting_crop_id');
  const cropInput = $('#crop');

  const load = function (id, typed) {
    select.empty();
    if (!id) return wrapper.addClass('d-none');

    $.getJSON(wrapper.data('source-url'), { crop_id: id }, function (names) {
      select.append($('<option>').text(cropInput.val()).val(''));
      names.forEach(function (alt) {
        const option = $('<option>').text(alt.name).val(alt.id);
        if (typed && alt.name.toLowerCase() === typed.toLowerCase()) option.prop('selected', true);
        select.append(option);
      });
      wrapper.toggleClass('d-none', names.length === 0);
    });
  };

  cropInput.on('autocompleteselect', function (event, ui) {
    const typed = ui.item.matched_alternate_name;
    setTimeout(function () {
      load(cropId.val(), typed);
    }, 0);
  });
});
