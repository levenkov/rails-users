import React from 'react';

const styles = {
  card: {
    background: '#fff',
    border: '1px solid #e0e0e0',
    borderRadius: 8,
    padding: '12px 16px',
    cursor: 'pointer',
    transition: 'all 1s',
    display: 'flex',
    flexDirection: 'column',
    gap: 4,
    marginBottom: 8,
  },
  title: {
    fontSize: 15,
    fontWeight: 500,
    color: '#202124',
    margin: 0,
    lineHeight: 1.4,
  },
  body: {
    fontSize: 13,
    color: '#5f6368',
    margin: 0,
    lineHeight: 1.5,
    whiteSpace: 'pre-wrap',
    overflow: 'hidden',
    display: '-webkit-box',
    WebkitLineClamp: 5,
    WebkitBoxOrient: 'vertical',
  },
  pointsList: {
    display: 'flex',
    flexDirection: 'column',
    margin: '4px 0',
  },
  pointItem: {
    display: 'flex',
    alignItems: 'flex-start',
    gap: 8,
    padding: '3px 0',
    fontSize: 13,
    color: '#202124',
    lineHeight: 1.4,
  },
  checkbox: {
    width: 16,
    height: 16,
    border: '2px solid #5f6368',
    borderRadius: 2,
    flexShrink: 0,
    marginTop: 1,
  },
  pointText: {
    flex: 1,
    overflow: 'hidden',
    textOverflow: 'ellipsis',
    whiteSpace: 'nowrap',
  },
  tagsRow: {
    display: 'flex',
    gap: 4,
    flexWrap: 'wrap',
    marginTop: 4,
  },
  tag: {
    fontSize: 11,
    padding: '2px 8px',
    borderRadius: 12,
    background: '#e8eaed',
    color: '#3c4043',
    fontWeight: 500,
  },
};

const NoteCard = ({note, onClick, onCtrlClick, dragging, highlighted}) => {
  return (
    <div
      style={{
        ...styles.card,
        ...(dragging ? {border: '2px solid #4F46E5', boxShadow: '0 4px 12px rgba(79,70,229,0.3)'} : {}),
        ...(highlighted ? {border: '2px solid #f59e0b', background: '#fffbeb'} : {}),
      }}
      onClick={e => {
        if (e.altKey) {
          e.stopPropagation();
          if (onCtrlClick) onCtrlClick(e);
          return;
        }
        onClick();
      }}
      onMouseEnter={e => {
        if (!dragging) {
          e.currentTarget.style.boxShadow = '0 1px 2px 0 rgba(60,64,67,0.3), 0 1px 3px 1px rgba(60,64,67,0.15)';
        }
      }}
      onMouseLeave={e => {
        if (!dragging) {
          e.currentTarget.style.boxShadow = 'none';
        }
      }}
    >
      {note.title && <h3 style={styles.title}>{note.title}</h3>}
      {note.body && <p style={styles.body}>{note.body}</p>}
      {(note.unchecked_points || []).length > 0 && (
        <div style={styles.pointsList}>
          {note.unchecked_points.map(p => (
            <div key={p.id} style={styles.pointItem}>
              <div style={styles.checkbox} />
              <span style={styles.pointText}>{p.text}</span>
            </div>
          ))}
        </div>
      )}
      {(note.tags || []).length > 0 && (
        <div style={styles.tagsRow}>
          {note.tags.map(t => (
            <span key={t.id} style={styles.tag}>{t.name}</span>
          ))}
        </div>
      )}
    </div>
  );
};

export default NoteCard;
