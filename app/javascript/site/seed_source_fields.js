// Toggles retail-only seed packet fields (e.g. brand and barcode)
// when the seed source is changed to or from 'retail outlet'.

export function updateRetailFields(form) {
  const sourceSelect = form.querySelector('select[name="seed[source]"]');
  if (!sourceSelect) return;

  const isRetail = sourceSelect.value === 'retail outlet';
  const retailFields = form.querySelectorAll('[data-retail-only]');
  retailFields.forEach((field) => {
    field.style.display = isRetail ? '' : 'none';
  });
}

export function initSeedSourceFields(root = document) {
  const forms = root.querySelectorAll('form');
  forms.forEach((form) => {
    const sourceSelect = form.querySelector('select[name="seed[source]"]');
    if (!sourceSelect) return;

    updateRetailFields(form);
    sourceSelect.addEventListener('change', () => updateRetailFields(form));
  });
}

if (typeof document !== 'undefined') {
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => initSeedSourceFields());
  } else {
    initSeedSourceFields();
  }
}
