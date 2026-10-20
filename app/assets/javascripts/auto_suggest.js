// Uses JQuery's autocomplete to make a suggestion in lieu of a
// preposterously long select dropdown. To implement add code to
// the view like this:
//
// = auto_suggest @resource, :auto_suggest_source
//
// You must also add a search method to the resource's controller.

jQuery(function () {
  const el = $('.auto-suggest');
  if (!el.length) return;

  const id = $('.auto-suggest-id');

  el.autocomplete({
    minLength: 1,
    source: el.attr('data-source-url'),
    focus: function (event, ui) {
      el.val(ui.item.name);
      id.val(ui.item.id);
      return false;
    },
    select: function (event, ui) {
      el.val(ui.item.name);
      id.val(ui.item.id);
      return false;
    },
    response: function (event, ui) {
      id.val('');
      ui.content.forEach(function (item) {
        if (item.name === el.val()) id.val(item.id);
      });
    }
  });

  const autocomplete = el.data('uiAutocomplete');
  if (autocomplete) {
    autocomplete._renderItem = function (ul, item) {
      const label = item.matched_alternate_name
        ? `<a>${item.matched_alternate_name} <small class="text-muted">(${item.name})</small></a>`
        : `<a>${item.name}</a>`;
      return $('<li class="list-group-item"></li>')
        .data('item.autocomplete', item)
        .append(label)
        .appendTo(ul);
    };
  }
});
