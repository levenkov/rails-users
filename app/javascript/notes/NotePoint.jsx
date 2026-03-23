import React, { useState, useRef } from 'react';
import { api } from './api';

const styles = {
  row: {
    display: 'flex',
    alignItems: 'flex-start',
    gap: 8,
    padding: '4px 0',
  },
  checkbox: {
    marginTop: 3,
    width: 16,
    height: 16,
    cursor: 'pointer',
    accentColor: '#4f46e5',
    flexShrink: 0,
  },
  text: {
    flex: 1,
    fontSize: 14,
    color: '#374151',
    border: 'none',
    outline: 'none',
    background: 'transparent',
    padding: '2px 0',
    lineHeight: 1.4,
    fontFamily: 'inherit',
  },
  textChecked: {
    textDecoration: 'line-through',
    color: '#9ca3af',
  },
  actions: {
    display: 'flex',
    gap: 4,
    opacity: 0.4,
    transition: 'opacity 0.15s',
  },
  btn: {
    background: 'none',
    border: 'none',
    cursor: 'pointer',
    fontSize: 14,
    color: '#9ca3af',
    padding: '2px 4px',
    borderRadius: 4,
    lineHeight: 1,
  },
  children: {
    paddingLeft: 24,
  },
  addChild: {
    display: 'flex',
    gap: 8,
    paddingLeft: 24,
    paddingTop: 4,
  },
  addInput: {
    flex: 1,
    fontSize: 13,
    border: '1px solid #e5e7eb',
    borderRadius: 6,
    padding: '4px 8px',
    outline: 'none',
    fontFamily: 'inherit',
  },
  addBtn: {
    fontSize: 13,
    padding: '4px 10px',
    background: '#f3f4f6',
    border: '1px solid #e5e7eb',
    borderRadius: 6,
    cursor: 'pointer',
    color: '#374151',
  },
};

const NotePoint = ({ point, noteId, onUpdate, depth = 0 }) => {
  const [text, setText] = useState(point.text);
  const [checked, setChecked] = useState(point.checked);
  const [children, setChildren] = useState(point.children || []);
  const [showAddChild, setShowAddChild] = useState(false);
  const [newChildText, setNewChildText] = useState('');
  const [hovered, setHovered] = useState(false);
  const textRef = useRef(null);

  const toggleChecked = async () => {
    const newVal = !checked;
    setChecked(newVal);
    await api.patch(`/notes/${noteId}/note_points/${point.id}`, {
      note_point: { checked: newVal }
    });
    if (onUpdate) onUpdate();
  };

  const saveText = async () => {
    if (text !== point.text) {
      await api.patch(`/notes/${noteId}/note_points/${point.id}`, {
        note_point: { text }
      });
      if (onUpdate) onUpdate();
    }
  };

  const handleDelete = async () => {
    await api.delete(`/notes/${noteId}/note_points/${point.id}`);
    if (onUpdate) onUpdate();
  };

  const addChild = async () => {
    if (!newChildText.trim()) return;
    const result = await api.post(`/notes/${noteId}/note_points`, {
      note_point: {
        text: newChildText.trim(),
        parent_id: point.id,
        position: children.length
      }
    });
    setChildren([...children, { ...result, children: [] }]);
    setNewChildText('');
    setShowAddChild(false);
    if (onUpdate) onUpdate();
  };

  const handleChildUpdate = () => {
    if (onUpdate) onUpdate();
  };

  return (
    <div>
      <div
        style={styles.row}
        onMouseEnter={() => setHovered(true)}
        onMouseLeave={() => setHovered(false)}
      >
        <input
          type="checkbox"
          checked={checked}
          onChange={toggleChecked}
          style={styles.checkbox}
        />
        <input
          ref={textRef}
          type="text"
          value={text}
          onChange={e => setText(e.target.value)}
          onBlur={saveText}
          onKeyDown={e => { if (e.key === 'Enter') textRef.current?.blur(); }}
          style={{
            ...styles.text,
            ...(checked ? styles.textChecked : {}),
          }}
        />
        <div style={{ ...styles.actions, opacity: hovered ? 1 : 0 }}>
          <button
            style={styles.btn}
            title="Add sub-item"
            onClick={() => setShowAddChild(!showAddChild)}
          >+</button>
          <button
            style={{ ...styles.btn, color: '#ef4444' }}
            title="Delete"
            onClick={handleDelete}
          >&times;</button>
        </div>
      </div>
      {children.length > 0 && (
        <div style={styles.children}>
          {children.map(child => (
            <NotePoint
              key={child.id}
              point={child}
              noteId={noteId}
              onUpdate={handleChildUpdate}
              depth={depth + 1}
            />
          ))}
        </div>
      )}
      {showAddChild && (
        <div style={styles.addChild}>
          <input
            style={styles.addInput}
            placeholder="Sub-item..."
            value={newChildText}
            onChange={e => setNewChildText(e.target.value)}
            onKeyDown={e => { if (e.key === 'Enter') addChild(); }}
            autoFocus
          />
          <button style={styles.addBtn} onClick={addChild}>Add</button>
        </div>
      )}
    </div>
  );
};

export default NotePoint;
