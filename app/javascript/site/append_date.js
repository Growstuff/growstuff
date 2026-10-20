// Displays datepicker to finished at date
// when marking a planting finished using a
// button. The button must have class 'append-date'.

jQuery(function () {
  const el = $('.append-date');

  el.datepicker({ format: 'yyyy-mm-dd' });

  el.on('click', function (e) {
    e.stopPropagation();
    e.preventDefault();

    const button = $(this);
    const originalText = button.text();
    const href = button.attr('href');
    button.text('Confirm without date');

    button.on('click.confirm', function () {
      const link = $(`<a href='${href}' data-method='put'></a>`);
      $('body').append(link);
      link.click();
    });

    button.on('blur', function () {
      button.text(originalText);
      button.off('click.confirm');
    });
  });

  el.one('changeDate', function () {
    const date = $(this).datepicker('getDate');
    const href = $(this).attr('href');
    const url = `${href}&planting[finished_at]=${date}`;

    const link = $(`<a href='${url}' data-method='put'></a>`);
    $('body').append(link);
    link.click();
  });
});
