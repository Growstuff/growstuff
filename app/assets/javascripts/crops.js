document.addEventListener('DOMContentLoaded', function () {
  const sciTemplate = "<div id='sci_template[INDEX]' class='template col-md-12'><div class='col-md-2'><label>Scientific name INDEX:</label></div><div class='col-md-8'><input name='sci_name[INDEX]' class='scientific-name-auto-suggest form-control' id='sci_name[INDEX]' data-source-url='/scientific_names/gbif_suggest'><span class='form-text'>Scientific name of crop</span><input type='text' id='sci_gbif_key[INDEX]' class=''></div><div class='col-md-2'></div></div>";

  // Adds and removes numbered rows in the list of scientific names. The buttons
  // are hidden until this script has run, because they do nothing without it.
  const rowButtons = function (prefix, listId, template) {
    const list = document.getElementById(listId);
    const add = document.querySelector(`.add-${prefix}name-row`);
    const remove = document.querySelector(`.remove-${prefix}name-row`);
    if (!list || !add || !remove) return;

    let index = list.querySelectorAll('.template').length + 1;

    add.style.display = 'inline-block';
    remove.style.display = 'inline-block';

    add.addEventListener('click', function () {
      list.insertAdjacentHTML('beforeend', template.split('INDEX').join(index));
      index += 1;
    });

    remove.addEventListener('click', function () {
      if (index > 2) {
        index -= 1;
        document.getElementById(`${prefix}_template[${index}]`).remove();
      }
    });
  };

  rowButtons('sci', 'scientific_names', sciTemplate);
});
