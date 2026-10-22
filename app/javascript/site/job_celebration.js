// The fuss made when a job is crossed off: flowers blooming out of the tick box,
// and the sticky note and Undo toast. A streak of jobs gets more flowers, a
// bigger message, and from three in a row a row of flowers growing along the
// bottom of the page. See job_streak.js.

import {flowerCount, levelFor, sproutCount} from './job_streak';

const PETALS = ['#ffa500', '#e4a0a0', '#fff3a8', '#c9a0dc', '#ff8a65', '#ffffff'];
const SHOW_FOR_MS = 7000;

let timer = null;

const reducedMotion = function () {
  return window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
};

export const fill = function (template, values) {
  return template.replace(/%\{(\w+)\}/g, function (_, key) { return values[key]; });
};

// A flower: five petals round a centre. Only our own colours go in the markup.
const flower = function (petals, size) {
  const el = document.createElement('span');
  el.setAttribute('aria-hidden', 'true');
  el.style.width = size + 'px';
  el.style.height = size + 'px';
  el.innerHTML = '<svg viewBox="-10 -10 20 20" width="100%" height="100%"><g fill="' + petals +
    '" stroke="#413f3b" stroke-opacity=".25" stroke-width=".4">' +
    [0, 72, 144, 216, 288].map(function (angle) {
      return '<circle cx="0" cy="-5.2" r="3.9" transform="rotate(' + angle + ')"/>';
    }).join('') +
    '</g><circle r="2.7" fill="#c9a800"/></svg>';
  return el;
};

const pick = function (list) {
  return list[Math.floor(Math.random() * list.length)];
};

// Flowers blooming out of the tick box, drifting up and out as they fade.
const bloom = function (origin, streak) {
  if (reducedMotion()) return;

  const spread = 100 + Math.min(streak, 6) * 30;
  for (let i = 0; i < flowerCount(streak); i++) {
    const el = flower(pick(PETALS), 18 + Math.random() * 18);
    el.className = 'notepad-flower';
    el.style.left = origin.x + 'px';
    el.style.top = origin.y + 'px';
    el.style.setProperty('--dx', (Math.random() * 2 - 1) * spread + 'px');
    el.style.setProperty('--dy', -(50 + Math.random() * spread) + 'px');
    el.style.setProperty('--rot', (Math.random() * 2 - 1) * 200 + 'deg');
    el.style.animationDelay = Math.random() * 0.25 + 's';
    el.addEventListener('animationend', function () { el.remove(); });
    document.body.appendChild(el);
  }
};

// Flowers growing up from the bottom of the page, one more for each job in a
// row. They stay until the note goes.
const grow = function (streak) {
  document.querySelectorAll('.notepad-sprout').forEach(function (el) { el.remove(); });
  if (reducedMotion()) return;

  for (let i = 0; i < sproutCount(streak); i++) {
    const sprout = document.createElement('span');
    sprout.className = 'notepad-sprout';
    sprout.setAttribute('aria-hidden', 'true');
    sprout.style.left = 4 + Math.random() * 92 + '%';
    sprout.style.setProperty('--height', 50 + Math.random() * 90 + 'px');
    sprout.style.animationDelay = i * 0.08 + 's';
    sprout.appendChild(flower(pick(PETALS), 30));
    document.body.appendChild(sprout);
  }
};

// The note and toast, in a live region so they are read out as well as seen.
const panel = function () {
  let el = document.getElementById('notepad-celebration');
  if (el) return el;

  el = document.createElement('div');
  el.id = 'notepad-celebration';
  el.setAttribute('role', 'status');
  el.setAttribute('aria-live', 'polite');
  document.body.appendChild(el);
  return el;
};

const sticky = function (level, done) {
  const note = document.createElement('div');
  note.className = 'notepad-celebration-note';

  const tape = document.createElement('span');
  tape.className = 'tape';
  note.appendChild(tape);

  const lead = document.createElement('div');
  lead.className = 'notepad-celebration-lead';
  lead.textContent = level.lead + ' ' + done;
  note.appendChild(lead);

  const sub = document.createElement('div');
  sub.className = 'notepad-celebration-sub';
  sub.textContent = level.note;
  note.appendChild(sub);
  return note;
};

const toast = function (text, undoText, onUndo) {
  const el = document.createElement('div');
  el.className = 'notepad-toast';
  el.appendChild(document.createTextNode(text));

  const undo = document.createElement('button');
  undo.type = 'button';
  undo.textContent = undoText;
  undo.addEventListener('click', function () {
    hide();
    onUndo();
  });
  el.appendChild(undo);
  return el;
};

export function hide() {
  clearTimeout(timer);
  const el = document.getElementById('notepad-celebration');
  if (el) el.innerHTML = '';
  document.querySelectorAll('.notepad-sprout').forEach(function (sprout) { sprout.remove(); });
}

// words: the strings from the page. name: the job. done: how many are done this
// week. streak: how many in a row. origin: where the tick box is. onUndo: puts
// the job back.
export function celebrate({words, name, done, streak, origin, onUndo}) {
  bloom(origin, streak);
  grow(streak);

  const el = panel();
  el.innerHTML = '';
  const count = fill(Number(done) === 1 ? words.done.one : words.done.other, {count: done});
  el.appendChild(sticky(words.levels[levelFor(streak)], count));
  el.appendChild(toast(fill(words.crossed_off, {name: name}), words.undo, onUndo));

  clearTimeout(timer);
  timer = setTimeout(hide, SHOW_FOR_MS);
}
