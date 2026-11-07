import {createLabel} from './site/label_pdf';

document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('form[data-print-label]').forEach((form) => {
    form.addEventListener('submit', async (event) => {
      event.preventDefault();
      const error = form.querySelector('[role="alert"]');
      const button = form.querySelector('button');
      error.hidden = true;
      button.disabled = true;
      try {
        await document.fonts.ready;
        const pdf = createLabel({
          width: Number(form.elements.width.value),
          height: Number(form.elements.height.value),
          name: form.dataset.name,
          url: form.dataset.url,
          date: form.dataset.date,
        });
        pdf.save(form.dataset.filename);
      } catch (failure) {
        error.textContent = failure instanceof RangeError ? form.dataset.sizeError : form.dataset.error;
        error.hidden = false;
      } finally {
        button.disabled = false;
      }
    });
  });
});
