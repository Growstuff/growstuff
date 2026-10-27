import React, {useState} from 'react';

import {patchJson} from '../api';
import Modal from './Modal';

// A button on a post's page that opens a dialog for choosing the card photo:
// the photo that stands for the post on the posts list, an author's page and
// shared links. The photos are the post's own. Saving reloads, because the
// page is server rendered.
export default function CardPhotoDialog({
  url, photos, selectedId = null, subject, excerpt = '', byline = '', addPhotoUrl = null, addPhotoLabel = '',
}) {
  const [open, setOpen] = useState(false);
  const [chosenId, setChosenId] = useState(selectedId || (photos[0] && photos[0].id));
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);

  const chosen = photos.find((p) => p.id === chosenId);

  async function save() {
    setSaving(true);
    setError(null);
    const {ok} = await patchJson(url, {post: {card_photo_id: chosenId}});
    if (ok) {
      setTimeout(() => window.location.reload(), 0);
      return;
    }
    setSaving(false);
    setError('The photo could not be saved. Try again.');
  }

  return (
    <>
      <button type="button" className="btn btn-sm btn-outline-secondary" onClick={() => setOpen(true)}>
        Change
      </button>
      {open && (
        <Modal title={`Card photo for “${subject}”`} titleId="card-photo-title" onClose={() => setOpen(false)}>
          <div className="modal-body">
            <p className="text-muted">
              Photos come from your Flickr account. This photo stands for your post wherever it appears as a card: the
              posts list, your page and links shared elsewhere.
            </p>
            {photos.length === 0 ? (
              <p>Pick a photo from Flickr for this post first, then you can choose it here.</p>
            ) : (
              <fieldset>
                <legend className="h6 text-uppercase">Photos in this post</legend>
                <div className="card-photo-choices">
                  {photos.map((photo) => (
                    <label key={photo.id} className="card-photo-choice">
                      <input
                        type="radio"
                        name="card_photo"
                        checked={photo.id === chosenId}
                        onChange={() => setChosenId(photo.id)}
                      />
                      <span className="card-photo-polaroid">
                        <img src={photo.thumbnail_url} alt="" />
                        <span>{photo.title}</span>
                      </span>
                    </label>
                  ))}
                </div>
              </fieldset>
            )}
            {addPhotoUrl && (
              <p className="mt-2">
                {/* The page's photo dialog opens from any [data-photo-dialog] link. */}
                <a
                  href={addPhotoUrl}
                  className="btn btn-sm btn-outline-secondary me-2"
                  data-photo-dialog
                  data-photo-label={addPhotoLabel}
                  onClick={() => setOpen(false)}
                >
                  Pick a different photo from Flickr
                </a>
                <span className="text-muted small">Or leave it empty and the first photo is used.</span>
              </p>
            )}
            {chosen && (
              <>
                <h3 className="h6 text-uppercase mt-3">How it will look</h3>
                <div className="card-photo-preview">
                  <img src={chosen.fullsize_url} alt="Preview of the card photo" />
                  <div>
                    <strong>{subject}</strong>
                    <p className="text-muted small mb-1">{excerpt}</p>
                    <small className="text-muted">{byline}</small>
                  </div>
                </div>
              </>
            )}
            {error && <div className="alert alert-danger mt-3" role="alert">{error}</div>}
          </div>
          <div className="modal-footer">
            <button type="button" className="btn btn-outline-secondary" onClick={() => setOpen(false)}>Cancel</button>
            <button type="button" className="btn btn-primary" disabled={!chosen || saving} onClick={save}>
              Use this photo
            </button>
          </div>
        </Modal>
      )}
    </>
  );
}
