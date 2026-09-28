import React, { useState, useRef, useEffect } from 'react';

const COLUMNS = [
  { id: 'planned', name: 'Planned', badgeClass: 'bg-primary' },
  { id: 'in_progress', name: 'In Progress', badgeClass: 'bg-warning text-dark' },
  { id: 'done', name: 'Recently Done', badgeClass: 'bg-success' }
];

export default function ActivitiesKanban({ initialActivities = [], newActivityUrl }) {
  const [activities, setActivities] = useState(initialActivities);
  const [filterText, setFilterText] = useState('');
  const [draggingCardId, setDraggingCardId] = useState(null);
  const [dragOverColumn, setDragOverColumn] = useState(null);

  // Touch / Pointer drag state
  const [touchDragCard, setTouchDragCard] = useState(null);
  const [touchPos, setTouchPos] = useState({ x: 0, y: 0 });
  const touchCardRef = useRef(null);
  const columnRefs = useRef({});

  const getCsrfToken = () => {
    const meta = document.querySelector('meta[name="csrf-token"]');
    return meta ? meta.getAttribute('content') : '';
  };

  const moveActivity = async (activityId, newStatus) => {
    const targetActivity = activities.find(a => a.id === activityId);
    if (!targetActivity || targetActivity.status === newStatus) return;

    // Optimistic update
    const previousActivities = [...activities];
    setActivities(prev =>
      prev.map(a => (a.id === activityId ? { ...a, status: newStatus } : a))
    );

    try {
      const response = await fetch(`/activities/${targetActivity.slug || targetActivity.id}.json`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': getCsrfToken(),
          'Accept': 'application/json'
        },
        body: JSON.stringify({ activity: { status: newStatus } })
      });

      if (!response.ok) {
        throw new Error('Failed to update activity status');
      }
    } catch (err) {
      console.error(err);
      // Rollback on failure
      setActivities(previousActivities);
    }
  };

  // Mouse Drag handlers
  const handleDragStart = (e, activityId) => {
    e.dataTransfer.setData('text/plain', String(activityId));
    e.dataTransfer.effectAllowed = 'move';
    setDraggingCardId(activityId);
  };

  const handleDragOver = (e, colId) => {
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';
    if (dragOverColumn !== colId) {
      setDragOverColumn(colId);
    }
  };

  const handleDragLeave = (colId) => {
    if (dragOverColumn === colId) {
      setDragOverColumn(null);
    }
  };

  const handleDrop = (e, colId) => {
    e.preventDefault();
    setDragOverColumn(null);
    setDraggingCardId(null);
    const cardIdStr = e.dataTransfer.getData('text/plain');
    const cardId = parseInt(cardIdStr, 10);
    if (cardId) {
      moveActivity(cardId, colId);
    }
  };

  const handleDragEnd = () => {
    setDraggingCardId(null);
    setDragOverColumn(null);
  };

  // Touch / Pointer Events drag handlers
  const handlePointerDown = (e, activity) => {
    // Only capture primary touch/pointer inside card handle or card
    if (e.pointerType === 'mouse') return; // let HTML5 drag-and-drop handle mouse
    const element = e.currentTarget;
    element.setPointerCapture(e.pointerId);

    setTouchDragCard(activity);
    setTouchPos({ x: e.clientX, y: e.clientY });
  };

  const handlePointerMove = (e) => {
    if (!touchDragCard) return;
    setTouchPos({ x: e.clientX, y: e.clientY });

    // Find column element directly under touch position
    const el = document.elementFromPoint(e.clientX, e.clientY);
    if (el) {
      const colEl = el.closest('[data-kanban-column]');
      if (colEl) {
        setDragOverColumn(colEl.dataset.kanbanColumn);
      } else {
        setDragOverColumn(null);
      }
    }
  };

  const handlePointerUp = (e) => {
    if (!touchDragCard) return;
    const el = document.elementFromPoint(e.clientX, e.clientY);
    if (el) {
      const colEl = el.closest('[data-kanban-column]');
      if (colEl) {
        const targetCol = colEl.dataset.kanbanColumn;
        moveActivity(touchDragCard.id, targetCol);
      }
    }
    setTouchDragCard(null);
    setDragOverColumn(null);
  };

  const filteredActivities = activities.filter(a => {
    if (!filterText.trim()) return true;
    const term = filterText.toLowerCase();
    return (
      (a.name && a.name.toLowerCase().includes(term)) ||
      (a.category && a.category.toLowerCase().includes(term)) ||
      (a.garden_name && a.garden_name.toLowerCase().includes(term)) ||
      (a.planting_name && a.planting_name.toLowerCase().includes(term)) ||
      (a.description && a.description.toLowerCase().includes(term))
    );
  });

  return (
    <div className="kanban-board-wrapper">
      <div className="kanban-board-header d-flex flex-wrap justify-content-between align-items-center mb-3">
        <div className="kanban-search mb-2 mb-md-0">
          <input
            type="text"
            className="form-control form-control-sm"
            placeholder="Filter activities..."
            value={filterText}
            onChange={e => setFilterText(e.target.value)}
          />
        </div>
        {newActivityUrl && (
          <a href={newActivityUrl} className="btn btn-primary btn-sm rounded-pill shadow-sm">
            <i className="fa fa-plus me-1" aria-hidden="true" /> New Activity
          </a>
        )}
      </div>

      <div className="kanban-board-columns">
        {COLUMNS.map(col => {
          const colActivities = filteredActivities.filter(a => a.status === col.id);
          const isOver = dragOverColumn === col.id;

          return (
            <div
              key={col.id}
              ref={el => (columnRefs.current[col.id] = el)}
              data-kanban-column={col.id}
              className={`kanban-column ${isOver ? 'is-drag-over' : ''}`}
              onDragOver={e => handleDragOver(e, col.id)}
              onDragLeave={() => handleDragLeave(col.id)}
              onDrop={e => handleDrop(e, col.id)}
            >
              <div className="kanban-column-header">
                <div className="d-flex align-items-center justify-content-between">
                  <h5 className="kanban-column-title mb-0">{col.name}</h5>
                  <span className={`badge ${col.badgeClass} rounded-pill`}>
                    {colActivities.length}
                  </span>
                </div>
              </div>

              <div className="kanban-column-cards">
                {colActivities.length === 0 ? (
                  <div className="kanban-empty-state text-muted text-center py-4">
                    <small>No activities</small>
                  </div>
                ) : (
                  colActivities.map(activity => (
                    <div
                      key={activity.id}
                      className={`kanban-card card shadow-sm ${
                        draggingCardId === activity.id ? 'is-dragging' : ''
                      }`}
                      draggable
                      onDragStart={e => handleDragStart(e, activity.id)}
                      onDragEnd={handleDragEnd}
                      onPointerDown={e => handlePointerDown(e, activity)}
                      onPointerMove={handlePointerMove}
                      onPointerUp={handlePointerUp}
                      onPointerCancel={handlePointerUp}
                    >
                      <div className="card-body p-3">
                        <div className="d-flex justify-content-between align-items-start mb-2">
                          <span className="badge bg-light text-dark border">
                            {activity.category}
                          </span>
                          {activity.due_date && (
                            <small className="text-muted kanban-due-date">
                              <i className="fa fa-calendar me-1" aria-hidden="true" />
                              {activity.due_date}
                            </small>
                          )}
                        </div>

                        <h6 className="card-title mb-1 fw-bold">
                          <a href={activity.url} className="text-decoration-none text-dark">
                            {activity.name}
                          </a>
                        </h6>

                        {(activity.garden_name || activity.planting_name) && (
                          <div className="kanban-card-context small text-muted mb-2">
                            {activity.garden_name && (
                              <span className="me-2">
                                <i className="fa fa-tree me-1" aria-hidden="true" />
                                {activity.garden_name}
                              </span>
                            )}
                            {activity.planting_name && (
                              <span>
                                <i className="fa fa-leaf me-1" aria-hidden="true" />
                                {activity.planting_name}
                              </span>
                            )}
                          </div>
                        )}

                        {activity.description && (
                          <p className="card-text small text-secondary mb-2 text-truncate">
                            {activity.description}
                          </p>
                        )}

                        <div className="kanban-card-actions d-flex justify-content-between align-items-center mt-2 pt-2 border-top">
                          <div className="btn-group btn-group-sm" role="group">
                            {COLUMNS.filter(c => c.id !== activity.status).map(c => (
                              <button
                                key={c.id}
                                type="button"
                                className="btn btn-outline-secondary btn-xs py-0 px-2"
                                title={`Move to ${c.name}`}
                                onClick={() => moveActivity(activity.id, c.id)}
                              >
                                &rarr; {c.name}
                              </button>
                            ))}
                          </div>
                        </div>
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>
          );
        })}
      </div>

      {/* Touch drag floating avatar */}
      {touchDragCard && (
        <div
          className="kanban-touch-avatar card shadow-lg p-2"
          style={{
            position: 'fixed',
            left: `${touchPos.x - 120}px`,
            top: `${touchPos.y - 40}px`,
            width: '240px',
            pointerEvents: 'none',
            zIndex: 9999,
            opacity: 0.95,
            transform: 'rotate(3deg)'
          }}
        >
          <div className="fw-bold text-truncate">{touchDragCard.name}</div>
          <small className="text-muted">{touchDragCard.category}</small>
        </div>
      )}
    </div>
  );
}
