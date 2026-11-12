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

  // What the field says about where you are, under it, for people and screen readers: the words come from the page.
  const hint = $('<div class="auto-suggest-hint" role="status" aria-live="polite"></div>').insertAfter(el);
  const words = el.data();

  function say(state, text) {
    hint.attr('data-state', state).text(text || '');
    el.toggleClass('is-chosen', state === 'chosen');
  }

  // Chosen once there is an id for the text; otherwise just typed, which is not enough.
  function describe() {
    if (id.val()) say('chosen', words.chosen.replace('{name}', el.val()));
    else if (el.val().trim()) say('typing', words.choose);
    else say('', '');
  }

  el.on('input', function () {
    id.val('');
    describe();
  });
  el.on('blur', function () {
    if (el.val().trim() && !id.val()) say('unchosen', words.unchosen);
  });
  describe();

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
      describe();
      return false;
    },
    search: function () {
      say('searching', words.searching);
    },
    response: function (event, ui) {
      id.val('');
      ui.content.forEach(function (item) {
        if (item.name === el.val()) id.val(item.id);
      });
      if (id.val()) describe();
      else if (ui.content.length) say('typing', words.choose);
      else say('none', words.none);
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
