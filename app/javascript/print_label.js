import {createLabel, createLabelImage} from './site/label_pdf';

document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('form[data-print-label]').forEach((form) => {
    const error = form.querySelector('[role="alert"]');
    const preview = form.querySelector('[data-label-preview]');
    const options = () => ({
      width: Number(form.elements.width.value),
      height: Number(form.elements.height.value),
      name: form.dataset.name,
      url: form.dataset.url,
      date: form.dataset.date,
      shortCode: form.dataset.shortCode,
    });
    const showError = (failure) => {
      error.textContent = failure instanceof RangeError ? form.dataset.sizeError : form.dataset.error;
      error.hidden = false;
    };
    async function updatePreview() {
      try {
        await document.fonts.ready;
        error.hidden = true;
        const label = options();
        preview.src = createLabelImage(label);
        preview.style.width = `${label.width}mm`;
        preview.hidden = false;
      } catch (failure) {
        preview.hidden = true;
        preview.removeAttribute('src');
        showError(failure);
      }
    }
    form.addEventListener('change', updatePreview);
    updatePreview();
    form.addEventListener('submit', async (event) => {
      event.preventDefault();
      const button = form.querySelector('button');
      error.hidden = true;
      button.disabled = true;
      try {
        await document.fonts.ready;
        const pdf = createLabel(options());
        pdf.save(form.dataset.filename);
      } catch (failure) {
        showError(failure);
      } finally {
        button.disabled = false;
      }
    });
  });
});
