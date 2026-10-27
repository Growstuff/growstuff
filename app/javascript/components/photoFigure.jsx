import React, {useState} from 'react';
import {Node} from '@tiptap/core';
import {NodeViewWrapper, ReactNodeViewRenderer} from '@tiptap/react';

const SIZES = [['wide', 'Wide'], ['half', 'Half'], ['pair', 'Pair']];

// ![caption](photo:123) or ![caption](photo:123/half), alone on its line, as
// the server reads it (see Haml::Filters::GrowstuffMarkdown).
const PATTERN = /^!\[([^[\]]*)\]\(photo:(\d+)(?:\/(wide|half|pair))?\)[ \t]*(?:\n|$)/;

const clean = (caption) => String(caption || '').replace(/[[\]\r\n]+/g, ' ').trim();

// The photo in the text, with the controls beside it: caption, size, which
// photo stands for the post, and removing it from the text.
function PhotoFigureView({node, updateAttributes, deleteNode, selected, extension}) {
  const {getPhoto, getCardPhotoId, setCardPhoto} = extension.options;
  const {photoId, caption, size} = node.attrs;
  const photo = getPhoto(photoId);
  const [cardPhotoId, setCardPhotoId] = useState(getCardPhotoId());
  const isCard = cardPhotoId === photoId;

  async function makeCard() {
    if (await setCardPhoto(photoId)) setCardPhotoId(photoId);
  }

  return (
    <NodeViewWrapper className={`photo-figure${selected ? ' photo-figure-selected' : ''}`} contentEditable={false}>
      <div className={`photo-figure-picture photo-figure-${size}`}>
        <div className="photo-figure-polaroid">
          {photo
            ? <img src={photo.fullsize_url} alt={caption || photo.title} />
            : <div className="photo-figure-missing">Photo {photoId}</div>}
          <div className="photo-figure-caption">{caption}</div>
        </div>
      </div>
      <div className="photo-figure-controls">
        <label className="fw-bold small d-block">
          Caption
          <input
            className="form-control form-control-sm"
            value={caption}
            onChange={(event) => updateAttributes({caption: clean(event.target.value)})}
          />
        </label>
        <div className="d-flex align-items-center gap-2 my-2">
          <span className="fw-bold small">Size</span>
          <div className="btn-group btn-group-sm" role="group" aria-label="Size">
            {SIZES.map(([value, label]) => (
              <button
                key={value}
                type="button"
                className={`btn btn-outline-secondary${size === value ? ' active' : ''}`}
                aria-pressed={size === value}
                onClick={() => updateAttributes({size: value})}
              >
                {label}
              </button>
            ))}
          </div>
        </div>
        <div className="d-flex gap-2">
          <button
            type="button"
            className={`btn btn-sm btn-outline-secondary${isCard ? ' active' : ''}`}
            aria-pressed={isCard}
            onClick={makeCard}
          >
            ★ Card photo
          </button>
          <button type="button" className="btn btn-sm btn-outline-secondary" onClick={deleteNode}>Remove</button>
        </div>
      </div>
    </NodeViewWrapper>
  );
}

// A Flickr photo in the body, drawn as a polaroid with its caption. Options:
// getPhoto(id) finds a photo ({fullsize_url, title}), getCardPhotoId() says which
// photo is the post's card photo, and setCardPhoto(id) makes one, resolving to
// whether it worked.
export default Node.create({
  name: 'photoFigure',
  group: 'block',
  atom: true,
  draggable: true,
  selectable: true,

  addOptions() {
    return {getPhoto: () => null, getCardPhotoId: () => null, setCardPhoto: async () => false};
  },

  addAttributes() {
    return {
      photoId: {default: null, parseHTML: (el) => Number(el.getAttribute('data-photo-id'))},
      caption: {default: '', parseHTML: (el) => el.getAttribute('data-caption') || ''},
      size: {default: 'wide', parseHTML: (el) => el.getAttribute('data-size') || 'wide'},
    };
  },

  parseHTML() {
    return [{tag: 'div[data-photo-figure]'}];
  },

  renderHTML({node}) {
    return ['div', {
      'data-photo-figure': '',
      'data-photo-id': node.attrs.photoId,
      'data-caption': node.attrs.caption,
      'data-size': node.attrs.size,
    }];
  },

  addNodeView() {
    return ReactNodeViewRenderer(PhotoFigureView);
  },

  markdownTokenizer: {
    name: 'photoFigure',
    level: 'block',
    start: (src) => src.search(/^!\[[^[\]]*\]\(photo:\d+/m),
    tokenize(src) {
      const match = PATTERN.exec(src);
      if (!match) return undefined;
      return {type: 'photoFigure', raw: match[0], caption: match[1], photoId: Number(match[2]), size: match[3] || 'wide'};
    },
  },

  parseMarkdown(token) {
    return {type: 'photoFigure', attrs: {photoId: token.photoId, caption: token.caption, size: token.size}};
  },

  renderMarkdown(node) {
    const {photoId, caption, size} = node.attrs;
    return `![${clean(caption)}](photo:${photoId}/${size})`;
  },
});
