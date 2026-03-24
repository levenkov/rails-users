import React, {useRef, useEffect} from 'react';
import {styles} from './NoteCard.styles';
import {useHover} from './useHover';

const NoteCard = ({
  id, title, body, unchecked_points, tags,
  onClick, onDragStart, onHeightMeasured, highlighted,
}) => {
  const cardRef = useRef(null);
  const [isHover, hoverProps] = useHover();

  useEffect(() => {
    if (cardRef.current && onHeightMeasured) {
      onHeightMeasured(id, cardRef.current.offsetHeight);
    }
  }, [title, body, unchecked_points, tags]);

  return (
    <div
      ref={cardRef}
      draggable
      style={{
        ...styles.card,
        ...(isHover ? styles.cardHover : null),
        ...(highlighted ? styles.cardHighlighted : null),
      }}
      onClick={onClick}
      onDragStart={onDragStart}
      {...hoverProps}
    >
      {title && <h3 style={styles.title}>{title}</h3>}

      {body && <p style={styles.body}>{body}</p>}

      {
        (unchecked_points || []).length > 0 && (
          <div style={styles.pointsList}>
            {
              unchecked_points.map(p => (
                <div key={p.id} style={styles.pointItem}>
                  <div style={styles.checkbox} />
                  <span style={styles.pointText}>{p.text}</span>
                </div>
              ))
            }
          </div>
        )
      }

      {
        (tags || []).length > 0 && (
          <div style={styles.tagsRow}>
            {
              tags.map(t => (
                <span key={t.id} style={styles.tag}>{t.name}</span>
              ))
            }
          </div>
        )
      }
    </div>
  );
};

export default NoteCard;
