jQuery(function () {
  $('.add-sciname-row, .remove-sciname-row, .add-altname-row, .remove-altname-row')
    .css('display', 'inline-block');

  const sciTemplate = "<div id='sci_template[INDEX]' class='template col-md-12'><div class='col-md-2'><label>Scientific name INDEX:</label></div><div class='col-md-8'><input name='sci_name[INDEX]' class='scientific-name-auto-suggest form-control' id='sci_name[INDEX]' data-source-url='/scientific_names/gbif_suggest'></input><span class='form-text'>Scientific name of crop</span><input type='text' id='sci_gbif_key[INDEX]' class=''></div><div class='col-md-2'></div></div>";
  const altTemplate = "<div id='alt_template[INDEX]' class='template col-md-12'><div class='col-md-2'><label>Alternate name INDEX:</label></div><div class='col-md-8'><input name='alt_name[INDEX]' class='form-control' id='alt_name[INDEX]'></input><span class='form-text'>Alternate name of crop.</span></div><div class='col-md-2'></div></div>";

  let sciIndex = $('#scientific_names .template').length + 1;
  let altIndex = $('#alternate_names .template').length + 1;

  $('.add-sciname-row').on('click', function () {
    $('#scientific_names').append($(sciTemplate.split('INDEX').join(sciIndex)));
    sciIndex += 1;
  });

  $('.remove-sciname-row').on('click', function () {
    if (sciIndex > 2) {
      sciIndex -= 1;
      document.getElementById(`sci_template[${sciIndex}]`).remove();
    }
  });

  $('.add-altname-row').on('click', function () {
    $('#alternate_names').append($(altTemplate.split('INDEX').join(altIndex)));
    altIndex += 1;
  });

  $('.remove-altname-row').on('click', function () {
    if (altIndex > 2) {
      altIndex -= 1;
      document.getElementById(`alt_template[${altIndex}]`).remove();
    }
  });
});
