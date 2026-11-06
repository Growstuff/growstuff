import {mergeAttributes, Node} from '@tiptap/core';
import {PluginKey} from '@tiptap/pm/state';
import Suggestion from '@tiptap/suggestion';

import {getJson} from '../api';

// How each kind of link is written in a post's markdown. Crops and members are
// found by name, plantings by slug, as the server expands them (see
// Haml::Filters::GrowstuffMarkdown).
const WRITTEN = {
  crop: () => 'crop',
  member: () => 'member',
  planting: ({slug}) => `planting:${slug}`,
};

const PATTERN = /^\[([^[\]]+)\]\((crop|member|planting:([\w-]+))\)/;

const clean = (label) => String(label).replace(/[[\]]/g, '');

// A link to a crop, a member or one of your plantings, shown in the text as a
// chip, and written as [name](crop), [name](member) or [name](planting:slug).
// It is added by typing @ and choosing from the list (see `suggestion`).
export function createLinkChip({suggestion}) {
  return Node.create({
    name: 'linkChip',
    group: 'inline',
    inline: true,
    atom: true,
    selectable: true,

    addAttributes() {
      return {
        kind: {default: 'crop', parseHTML: (el) => el.getAttribute('data-kind')},
        label: {default: '', parseHTML: (el) => el.getAttribute('data-label')},
        slug: {default: null, parseHTML: (el) => el.getAttribute('data-slug')},
      };
    },

    parseHTML() {
      return [{tag: 'span[data-link-chip]'}];
    },

    renderHTML({node, HTMLAttributes}) {
      return [
        'span',
        mergeAttributes(HTMLAttributes, {
          'data-link-chip': '',
          'data-kind': node.attrs.kind,
          'data-label': node.attrs.label,
          'data-slug': node.attrs.slug,
          'class': `link-chip link-chip-${node.attrs.kind}`,
        }),
        `@${node.attrs.label}`,
      ];
    },

    renderText({node}) {
      return `@${node.attrs.label}`;
    },

    markdownTokenizer: {
      name: 'linkChip',
      level: 'inline',
      start: (src) => src.search(/\[[^[\]]+\]\((?:crop|member|planting:[\w-]+)\)/),
      tokenize(src) {
        const match = PATTERN.exec(src);
        if (!match) return undefined;
        const kind = match[2].split(':')[0];
        return {type: 'linkChip', raw: match[0], kind, label: match[1], slug: match[3] || null};
      },
    },

    parseMarkdown(token) {
      return {type: 'linkChip', attrs: {kind: token.kind, label: token.label, slug: token.slug}};
    },

    renderMarkdown(node) {
      const {kind, label, slug} = node.attrs;
      return `[${clean(label)}](${WRITTEN[kind]({slug})})`;
    },

    addProseMirrorPlugins() {
      return [
        Suggestion({
          editor: this.editor,
          pluginKey: new PluginKey('linkChipSuggestion'),
          char: '@',
          allowSpaces: false,
          command: ({editor, range, props}) => {
            editor
              .chain()
              .focus()
              .insertContentAt(range, [
                {type: 'linkChip', attrs: {kind: props.kind, label: clean(props.label), slug: props.slug || null}},
                {type: 'text', text: ' '},
              ])
              .run();
          },
          ...suggestion,
        }),
      ];
    },
  });
}

const PER_GROUP = 5;
const SEARCH_DELAY = 200; // ms to wait for typing to pause before searching

// What @ can link to matching `term`: crops, members, and your own plantings.
// Each is {group, kind, label, slug?, detail?}.
export async function fetchLinkItems(term, {signal} = {}) {
  const query = encodeURIComponent(term);
  const [crops, others] = await Promise.all([
    getJson(`/crops/search.json?term=${query}`, {signal}),
    getJson(`/posts/link_suggestions.json?term=${query}`, {signal}),
  ]);

  const items = [];
  if (crops.ok && Array.isArray(crops.data)) {
    crops.data.slice(0, PER_GROUP).forEach((crop) => {
      items.push({group: 'Crops', kind: 'crop', label: crop.name, detail: crop.matched_alternate_name});
    });
  }
  if (others.ok && others.data) {
    (others.data.members || []).forEach((member) => {
      items.push({group: 'Members', kind: 'member', label: member.name});
    });
    (others.data.plantings || []).forEach((planting) => {
      items.push({group: 'Yours', kind: 'planting', label: planting.name, slug: planting.slug, detail: 'Planting'});
    });
  }
  return items;
}

// The `items` for the suggestion: searches once typing pauses. A search that a
// newer one has overtaken answers with the last results, so they never go back.
export function createLinkSearch() {
  let latest = 0;
  let last = [];
  return async function search(term) {
    if (!term.trim()) return [];
    const id = ++latest;
    await new Promise((resolve) => setTimeout(resolve, SEARCH_DELAY));
    if (id !== latest) return last;
    const items = await fetchLinkItems(term);
    if (id !== latest) return last;
    last = items;
    return items;
  };
}
