export function initLabelPreferences(root = document) {
  root.querySelectorAll('[data-label-size-preferences]').forEach((fields) => {
    const preset = fields.querySelector('[data-label-size-preset]');
    const width = fields.querySelector('[data-label-width]');
    const height = fields.querySelector('[data-label-height]');
    if (!width.value && !height.value) {
      preset.value = 'default';
    } else {
      const match = [...preset.options].find((option) => {
        const [w, h] = option.value.split('x').map(Number);
        return w === Number(width.value) && h === Number(height.value);
      });
      preset.value = match?.value || '';
    }
    preset.addEventListener('change', () => {
      if (!preset.value) return;
      const sizes = preset.value === 'default' ? ['', ''] : preset.value.split('x');
      [width.value, height.value] = sizes;
    });
    [width, height].forEach((input) => {
      input.addEventListener('input', () => { preset.value = ''; });
    });
  });
}

document.addEventListener('DOMContentLoaded', () => initLabelPreferences());
