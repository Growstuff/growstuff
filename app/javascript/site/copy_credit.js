// A button with data-copy-text copies that text to the clipboard, and says so for a
// moment by swapping its label for data-copied.
export function copyText(button, clipboard = navigator.clipboard) {
  const label = button.textContent;
  return clipboard.writeText(button.dataset.copyText).then(() => {
    button.textContent = button.dataset.copied || label;
    setTimeout(() => { button.textContent = label; }, 2000);
  });
}

document.addEventListener('click', (event) => {
  const button = event.target.closest('[data-copy-text]');
  if (button && navigator.clipboard) copyText(button);
});
