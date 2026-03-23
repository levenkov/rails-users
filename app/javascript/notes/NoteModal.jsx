import React, { useState, useEffect, useRef, useCallback } from 'react';
import { api } from './api';

const styles = {
  backdrop: {
    position: 'fixed',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    background: 'rgba(0,0,0,0.5)',
    display: 'flex',
    alignItems: 'flex-start',
    justifyContent: 'center',
    zIndex: 1000,
    overflowY: 'auto',
    padding: '5vh 16px',
  },
  modal: {
    background: '#fff',
    borderRadius: 8,
    width: '100%',
    maxWidth: 600,
    boxShadow: '0 8px 28px rgba(0,0,0,0.28)',
    display: 'flex',
    flexDirection: 'column',
    position: 'relative',
  },
  topBar: {
    display: 'flex',
    alignItems: 'center',
    padding: '8px 8px 0 8px',
  },
  backBtn: {
    display: 'inline-flex',
    alignItems: 'center',
    background: 'none',
    border: 'none',
    cursor: 'pointer',
    padding: 8,
    borderRadius: '50%',
    color: '#5f6368',
  },
  content: {
    padding: '4px 16px 0 16px',
  },
  titleInput: {
    width: '100%',
    fontSize: 18,
    fontWeight: 500,
    border: 'none',
    outline: 'none',
    padding: '8px 0',
    color: '#202124',
    background: 'transparent',
    fontFamily: 'inherit',
  },
  bodyTextarea: {
    width: '100%',
    fontSize: 14,
    border: 'none',
    outline: 'none',
    padding: '4px 0',
    color: '#202124',
    background: 'transparent',
    fontFamily: 'inherit',
    resize: 'none',
    lineHeight: 1.5,
    minHeight: 40,
  },
  pointsSection: {
    padding: '8px 0',
  },
  pointRow: {
    display: 'flex',
    alignItems: 'flex-start',
    gap: 8,
    padding: '2px 0',
  },
  pointCheckbox: {
    marginTop: 4,
    width: 18,
    height: 18,
    cursor: 'pointer',
    accentColor: '#4f46e5',
    flexShrink: 0,
  },
  pointInput: {
    flex: 1,
    fontSize: 14,
    color: '#202124',
    border: 'none',
    outline: 'none',
    background: 'transparent',
    padding: '2px 0',
    lineHeight: 1.5,
    fontFamily: 'inherit',
  },
  pointInputChecked: {
    textDecoration: 'line-through',
    color: '#5f6368',
  },
  completedDivider: {
    display: 'flex',
    alignItems: 'center',
    gap: 8,
    padding: '8px 0 4px 0',
    cursor: 'pointer',
    userSelect: 'none',
  },
  completedArrow: {
    color: '#5f6368',
    fontSize: 12,
    transition: 'transform 0.2s',
  },
  completedText: {
    fontSize: 13,
    color: '#5f6368',
    fontWeight: 500,
  },
  completedLine: {
    flex: 1,
    height: 1,
    background: '#e0e0e0',
  },
  tagsSection: {
    display: 'flex',
    flexWrap: 'wrap',
    gap: 6,
    alignItems: 'center',
    padding: '8px 16px',
  },
  tag: {
    display: 'inline-flex',
    alignItems: 'center',
    gap: 4,
    fontSize: 12,
    padding: '4px 10px',
    borderRadius: 12,
    background: '#e8eaed',
    color: '#3c4043',
    fontWeight: 500,
  },
  tagRemove: {
    background: 'none',
    border: 'none',
    cursor: 'pointer',
    color: '#5f6368',
    fontSize: 14,
    padding: 0,
    lineHeight: 1,
  },
  tagInput: {
    fontSize: 12,
    border: '1px solid #e0e0e0',
    borderRadius: 12,
    padding: '4px 10px',
    outline: 'none',
    width: 100,
    fontFamily: 'inherit',
  },
  bottomBar: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: '8px 16px',
    borderTop: '1px solid #e0e0e0',
  },
  bottomBarBtn: {
    fontSize: 13,
    color: '#5f6368',
    background: 'none',
    border: 'none',
    cursor: 'pointer',
    padding: '6px 8px',
    borderRadius: 4,
  },
  deleteBtn: {
    fontSize: 13,
    color: '#5f6368',
    background: 'none',
    border: 'none',
    cursor: 'pointer',
    padding: '6px 8px',
    borderRadius: 4,
  },
  closeBtn: {
    fontSize: 14,
    fontWeight: 500,
    color: '#202124',
    background: 'none',
    border: 'none',
    cursor: 'pointer',
    padding: '6px 16px',
    borderRadius: 4,
  },
  loading: {
    padding: 40,
    textAlign: 'center',
    color: '#5f6368',
    fontSize: 14,
  },
};

const NoteModal = ({ noteId, onClose, isNew }) => {
  const [note, setNote] = useState(null);
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [tags, setTags] = useState([]);
  const [uncheckedPoints, setUncheckedPoints] = useState([]);
  const [checkedPoints, setCheckedPoints] = useState([]);
  const [showCompleted, setShowCompleted] = useState(false);
  const [newTagName, setNewTagName] = useState('');
  const [loading, setLoading] = useState(!isNew);
  const titleRef = useRef(null);
  const bodyRef = useRef(null);
  const dirtyRef = useRef(false);
  const pointRefsMap = useRef({});
  const modalRef = useRef(null);

  const fetchNote = useCallback(async () => {
    const data = await api.get(`/notes/${noteId}.json`);
    setNote(data);
    setTitle(data.title || '');
    setBody(data.body || '');
    setTags(data.tags || []);
    const allPoints = flattenPoints(data.points || []);
    setUncheckedPoints(allPoints.filter(p => !p.checked));
    setCheckedPoints(allPoints.filter(p => p.checked));
    setLoading(false);
  }, [noteId]);

  const flattenPoints = (points) => {
    const result = [];
    const walk = (items) => {
      items.forEach(p => {
        result.push(p);
        if (p.children && p.children.length > 0) walk(p.children);
      });
    };
    walk(points);
    return result;
  };

  useEffect(() => {
    if (!isNew) {
      fetchNote();
    } else {
      setLoading(false);
      setTimeout(() => titleRef.current?.focus(), 50);
    }
  }, [fetchNote, isNew]);

  const autoGrow = (el) => {
    if (el) {
      el.style.height = 'auto';
      el.style.height = el.scrollHeight + 'px';
    }
  };

  useEffect(() => {
    if (bodyRef.current) autoGrow(bodyRef.current);
  }, [body]);

  const handleSaveOnClose = async () => {
    if (!dirtyRef.current) return;
    const tagNames = tags.map(t => t.name).join(', ');
    await api.patch(`/notes/${noteId}`, {
      note: { title, body, tag_names: tagNames }
    });
  };

  const handleClose = async () => {
    await handleSaveOnClose();
    onClose();
  };

  const handleBackdropClick = (e) => {
    if (e.target === e.currentTarget) {
      handleClose();
    }
  };

  useEffect(() => {
    const handleEsc = (e) => {
      if (e.key === 'Escape') handleClose();
    };
    document.addEventListener('keydown', handleEsc);
    return () => document.removeEventListener('keydown', handleEsc);
  }, [title, body, tags]);

  const markDirty = () => { dirtyRef.current = true; };

  // Checkpoint handlers
  const handlePointToggle = async (point, isChecked) => {
    const newChecked = !point.checked;
    // Optimistic update
    if (newChecked) {
      const updated = { ...point, checked: true };
      setUncheckedPoints(prev => prev.filter(p => p.id !== point.id));
      setCheckedPoints(prev => [...prev, updated]);
    } else {
      const updated = { ...point, checked: false };
      setCheckedPoints(prev => prev.filter(p => p.id !== point.id));
      setUncheckedPoints(prev => [...prev, updated]);
    }
    await api.patch(`/notes/${noteId}/note_points/${point.id}`, {
      note_point: { checked: newChecked }
    });
  };

  const handlePointTextChange = (pointId, newText, listSetter) => {
    listSetter(prev => prev.map(p =>
      p.id === pointId ? { ...p, text: newText } : p
    ));
  };

  const handlePointTextBlur = async (point) => {
    await api.patch(`/notes/${noteId}/note_points/${point.id}`, {
      note_point: { text: point.text }
    });
  };

  const handlePointKeyDown = async (e, point, index) => {
    if (e.key === 'Enter') {
      e.preventDefault();
      const newPosition = index + 1;
      const result = await api.post(`/notes/${noteId}/note_points`, {
        note_point: { text: '', position: newPosition }
      });
      const newPoint = { ...result, children: [] };
      setUncheckedPoints(prev => {
        const next = [...prev];
        next.splice(index + 1, 0, newPoint);
        return next;
      });
      setTimeout(() => {
        const ref = pointRefsMap.current[result.id];
        if (ref) ref.focus();
      }, 50);
    }
    if (e.key === 'Backspace' && point.text === '') {
      e.preventDefault();
      await api.delete(`/notes/${noteId}/note_points/${point.id}`);
      setUncheckedPoints(prev => prev.filter(p => p.id !== point.id));
      // Focus previous point
      if (index > 0) {
        const prevPoint = uncheckedPoints[index - 1];
        if (prevPoint) {
          setTimeout(() => {
            const ref = pointRefsMap.current[prevPoint.id];
            if (ref) ref.focus();
          }, 50);
        }
      }
    }
  };

  // Tags
  const addTag = async () => {
    const name = newTagName.trim();
    if (!name) return;
    const newTags = [...tags, { name, id: 'temp-' + Date.now() }];
    setTags(newTags);
    setNewTagName('');
    markDirty();
  };

  const removeTag = (tagToRemove) => {
    setTags(prev => prev.filter(t => t.id !== tagToRemove.id));
    markDirty();
  };

  const handleTagKeyDown = (e) => {
    if (e.key === 'Enter' || e.key === ',') {
      e.preventDefault();
      addTag();
    }
  };

  // Delete
  const deleteNote = async () => {
    if (!confirm('Delete this note?')) return;
    await api.delete(`/notes/${noteId}`);
    onClose();
  };

  const renderPoint = (point, index, list, listSetter) => (
    <div key={point.id} style={styles.pointRow}>
      <input
        type="checkbox"
        checked={point.checked}
        onChange={() => handlePointToggle(point)}
        style={styles.pointCheckbox}
      />
      <input
        ref={el => { pointRefsMap.current[point.id] = el; }}
        type="text"
        value={point.text}
        onChange={e => handlePointTextChange(point.id, e.target.value, listSetter)}
        onBlur={() => {
          const current = list.find(p => p.id === point.id);
          if (current) handlePointTextBlur(current);
        }}
        onKeyDown={e => handlePointKeyDown(e, point, index)}
        style={{
          ...styles.pointInput,
          ...(point.checked ? styles.pointInputChecked : {}),
        }}
        placeholder="List item"
      />
    </div>
  );

  if (loading) {
    return (
      <div style={styles.backdrop} onClick={handleBackdropClick}>
        <div style={styles.modal}>
          <div style={styles.loading}>Loading...</div>
        </div>
      </div>
    );
  }

  return (
    <div style={styles.backdrop} onClick={handleBackdropClick}>
      <div style={styles.modal} ref={modalRef} onClick={e => e.stopPropagation()}>
        {/* Top bar with back arrow */}
        <div style={styles.topBar}>
          <button style={styles.backBtn} onClick={handleClose} title="Close">
            <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 19l-7-7 7-7"/>
            </svg>
          </button>
        </div>

        {/* Content */}
        <div style={styles.content}>
          <input
            ref={titleRef}
            type="text"
            value={title}
            onChange={e => { setTitle(e.target.value); markDirty(); }}
            placeholder="Title"
            style={styles.titleInput}
          />
          <textarea
            ref={bodyRef}
            value={body}
            onChange={e => { setBody(e.target.value); markDirty(); autoGrow(e.target); }}
            placeholder="Take a note..."
            style={styles.bodyTextarea}
          />

          {/* Unchecked points */}
          {(uncheckedPoints.length > 0 || checkedPoints.length > 0) && (
            <div style={styles.pointsSection}>
              {uncheckedPoints.map((p, i) =>
                renderPoint(p, i, uncheckedPoints, setUncheckedPoints)
              )}
            </div>
          )}

          {/* Add new point */}
          <div
              style={{ ...styles.pointRow, opacity: 0.5 }}
              onClick={async () => {
                const result = await api.post(`/notes/${noteId}/note_points`, {
                  note_point: { text: '', position: uncheckedPoints.length }
                });
                const newPoint = { ...result, children: [] };
                setUncheckedPoints(prev => [...prev, newPoint]);
                setTimeout(() => {
                  const ref = pointRefsMap.current[result.id];
                  if (ref) ref.focus();
                }, 50);
              }}
            >
              <div style={{ ...styles.pointCheckbox, border: '2px solid #e0e0e0', borderRadius: 2, width: 18, height: 18 }} />
              <span style={{ ...styles.pointInput, color: '#5f6368', cursor: 'pointer' }}>
                + List item
              </span>
            </div>

          {/* Completed items divider */}
          {checkedPoints.length > 0 && (
            <>
              <div
                style={styles.completedDivider}
                onClick={() => setShowCompleted(!showCompleted)}
              >
                <span style={{
                  ...styles.completedArrow,
                  transform: showCompleted ? 'rotate(90deg)' : 'rotate(0deg)',
                }}>
                  &#9654;
                </span>
                <span style={styles.completedText}>
                  {checkedPoints.length} completed {checkedPoints.length === 1 ? 'item' : 'items'}
                </span>
                <div style={styles.completedLine} />
              </div>
              {showCompleted && (
                <div style={styles.pointsSection}>
                  {checkedPoints.map((p, i) =>
                    renderPoint(p, i, checkedPoints, setCheckedPoints)
                  )}
                </div>
              )}
            </>
          )}
        </div>

        {/* Tags */}
        <div style={styles.tagsSection}>
          {tags.map(tag => (
            <span key={tag.id} style={styles.tag}>
              {tag.name}
              <button style={styles.tagRemove} onClick={() => removeTag(tag)}>&times;</button>
            </span>
          ))}
          <input
            style={styles.tagInput}
            placeholder="Add tag..."
            value={newTagName}
            onChange={e => setNewTagName(e.target.value)}
            onKeyDown={handleTagKeyDown}
          />
        </div>

        {/* Bottom bar */}
        <div style={styles.bottomBar}>
          <button style={styles.deleteBtn} onClick={deleteNote}>
            <svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24" style={{ verticalAlign: 'middle', marginRight: 4 }}>
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
            </svg>
            Delete
          </button>
          <button style={styles.closeBtn} onClick={handleClose}>Close</button>
        </div>
      </div>
    </div>
  );
};

export default NoteModal;
