import { init as initShareon } from 'shareon';

export function init() {
  if (document.querySelector('.shareon')) {
    initShareon();
  }
}

document.addEventListener('DOMContentLoaded', init);
