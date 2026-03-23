import React, {useState, useEffect, useRef, useCallback, useMemo} from 'react';
import {api} from './api';
import NoteCard from './NoteCard';

const GAP = 8;
const DRAG_THROTTLE_MS = 50;

const getColumnCount = (width) => {
  if (width >= 1200) return 5;
  if (width >= 900) return 4;
  if (width >= 600) return 3;
  return 2;
};

const NotesList = ({onSelectNote, onNewNote}) => {
  const [notes, setNotes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [layout, setLayout] = useState(null);
  const [draggingNoteId, setDraggingNoteId] = useState(null);
  const [dragPos, setDragPos] = useState(null);
  const [homunculusOrder, setHomunculusOrder] = useState(null);
  const containerRef = useRef(null);
  const measuringRef = useRef(null);
  const masonryRef = useRef(null);
  const dragOffsetRef = useRef({x: 0, y: 0});
  const dragThrottleRef = useRef(null);
  const draggingHeightRef = useRef(0);

  const fetchNotes = async () => {
    setLoading(true);
    const data = await api.get('/notes.json');
    setNotes(data);
    setLoading(false);
  };

  useEffect(() => {
    fetchNotes();
  }, []);

  // Index where homunculus should appear (starts at dragged note's index)
  const [homunculusIndex, setHomunculusIndex] = useState(null);
  const [debugInfo, setDebugInfo] = useState(null);
  const [closestNoteId, setClosestNoteId] = useState(null);

  // Build the ordered list with homunculus replacing the dragged note
  const layoutNotes = useMemo(() => {
    if (!draggingNoteId || homunculusIndex === null) return notes;

    const draggingNote = notes.find(n => n.id === draggingNoteId);
    if (!draggingNote) return notes;

    const others = notes.filter(n => n.id !== draggingNoteId);
    const homunculus = {
      id: '__homunculus__',
      _isHomunculus: true,
      _sourceId: draggingNoteId,
    };

    const idx = Math.max(0, Math.min(homunculusIndex, others.length));
    const result = [...others];
    result.splice(idx, 0, homunculus);
    return result;
  }, [notes, draggingNoteId, homunculusIndex]);

  const computeLayout = useCallback(() => {
    if (!measuringRef.current || !containerRef.current || layoutNotes.length === 0) return;

    const containerWidth = containerRef.current.offsetWidth;
    const colCount = getColumnCount(containerWidth);
    const colWidth = (containerWidth - GAP * (colCount - 1)) / colCount;

    // Set measuring container width imperatively before reading heights
    measuringRef.current.style.width = colWidth + 'px';

    // Force reflow
    void measuringRef.current.offsetHeight;

    const cards = measuringRef.current.children;
    const heights = [];
    for (let i = 0; i < cards.length; i++) {
      heights.push(cards[i].offsetHeight);
    }

    const colHeights = new Array(colCount).fill(0);
    const positions = [];

    for (let i = 0; i < heights.length; i++) {
      let minCol = 0;
      for (let c = 1; c < colCount; c++) {
        if (colHeights[c] < colHeights[minCol]) {
          minCol = c;
        }
      }

      positions.push({
        left: minCol * (colWidth + GAP),
        top: colHeights[minCol],
        width: colWidth,
      });

      colHeights[minCol] += heights[i] + GAP;
    }

    const totalHeight = Math.max(...colHeights, 0);
    setLayout({positions, totalHeight, colWidth});
  }, [layoutNotes]);

  useEffect(() => {
    if (layoutNotes.length === 0) return;
    requestAnimationFrame(() => {
      requestAnimationFrame(() => computeLayout());
    });
  }, [layoutNotes, computeLayout]);

  useEffect(() => {
    const handleResize = () => computeLayout();
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, [computeLayout]);

  // Determine target index from floating card's left-top position
  const computeIndexFromPosition = useCallback((floatLeft, floatTop) => {
    if (!layout || !layoutNotes.length) return 0;

    // Collect non-homunculus, non-dragging items with their positions and original index
    const items = [];
    let indexInOthers = 0;
    layoutNotes.forEach((n, i) => {
      if (n._isHomunculus) return;
      if (n.id === draggingNoteId) return;
      if (layout.positions[i]) {
        items.push({
          index: indexInOthers,
          left: layout.positions[i].left,
          top: layout.positions[i].top,
        });
      }
      indexInOthers++;
    });

    if (items.length === 0) return 0;

    // Compute distances to all items
    const dists = items.map((item, i) => {
      const dx = floatLeft - item.left;
      const dy = floatTop - item.top;
      return {i, index: item.index, dist: Math.sqrt(dx * dx + dy * dy), item};
    });
    dists.sort((a, b) => a.dist - b.dist);

    const closest = dists[0];
    const secondClosest = dists.length > 1 ? dists[1] : null;

    // Find the note title for debug
    const others = layoutNotes.filter(n => !n._isHomunculus && n.id !== draggingNoteId);
    const closestNote = others[closest.index];

    setDebugInfo({
      floatLeft: Math.round(floatLeft),
      floatTop: Math.round(floatTop),
      closestLeft: Math.round(closest.item.left),
      closestTop: Math.round(closest.item.top),
      closestTitle: closestNote?.title || '(untitled)',
      closestIdx: closest.index,
    });
    setClosestNoteId({id: closestNote?.id || null, dist: closest.dist});

    // Only switch homunculus if closest is 5x closer than second closest
    if (!secondClosest || closest.dist * 5 < secondClosest.dist) {
      return closest.index;
    }

    // Otherwise keep current position
    return homunculusIndex !== null ? homunculusIndex : closest.index;
  }, [layout, layoutNotes, draggingNoteId, homunculusIndex]);

  // Mouse move handler with throttle
  useEffect(() => {
    if (!draggingNoteId) return;

    const handleMouseMove = (e) => {
      if (!masonryRef.current) return;
      const masonryRect = masonryRef.current.getBoundingClientRect();
      const newLeft = e.clientX - masonryRect.left - dragOffsetRef.current.x;
      const newTop = e.clientY - masonryRect.top - dragOffsetRef.current.y;
      setDragPos({left: newLeft, top: newTop});

      // Throttled index recalculation
      if (!dragThrottleRef.current) {
        dragThrottleRef.current = setTimeout(() => {
          dragThrottleRef.current = null;
          const newIndex = computeIndexFromPosition(newLeft, newTop);
          setHomunculusIndex(prev => prev === newIndex ? prev : newIndex);
        }, DRAG_THROTTLE_MS);
      }
    };

    window.addEventListener('mousemove', handleMouseMove);
    return () => {
      window.removeEventListener('mousemove', handleMouseMove);
      if (dragThrottleRef.current) {
        clearTimeout(dragThrottleRef.current);
        dragThrottleRef.current = null;
      }
    };
  }, [draggingNoteId, computeIndexFromPosition]);

  // Start drag
  const startDrag = (note, i, e) => {
    const masonryRect = masonryRef.current.getBoundingClientRect();
    const cardPos = layout.positions[i];
    dragOffsetRef.current = {
      x: e.clientX - masonryRect.left - cardPos.left,
      y: e.clientY - masonryRect.top - cardPos.top,
    };
    draggingHeightRef.current = measuringRef.current?.children[i]?.offsetHeight || 50;
    const noteIndex = notes.findIndex(n => n.id === note.id);
    setHomunculusIndex(noteIndex);
    setDraggingNoteId(note.id);
    setDragPos({left: cardPos.left, top: cardPos.top});
  };

  // Drop
  const drop = async () => {
    if (!draggingNoteId || homunculusIndex === null) return;

    // Compute new order based on neighbors at homunculus position
    const others = notes.filter(n => n.id !== draggingNoteId);
    const prevNote = homunculusIndex > 0 ? others[homunculusIndex - 1] : null;
    const nextNote = homunculusIndex < others.length ? others[homunculusIndex] : null;

    let newOrder;
    if (!prevNote && nextNote) {
      newOrder = Math.max(1, Math.floor(nextNote.order / 2));
    } else if (prevNote && !nextNote) {
      newOrder = prevNote.order + 1000;
    } else if (prevNote && nextNote) {
      newOrder = Math.floor((prevNote.order + nextNote.order) / 2);
    } else {
      newOrder = 1000;
    }

    const note = notes.find(n => n.id === draggingNoteId);
    if (note && note.order !== newOrder) {
      await api.patch(`/notes/${draggingNoteId}`, {note: {order: newOrder}});
      fetchNotes();
    }

    setDraggingNoteId(null);
    setDragPos(null);
    setHomunculusIndex(null);
    setClosestNoteId({id: null, dist: Infinity});
    setDebugInfo(null);
  };

  if (loading) {
    return <div style={styles.loading}>Loading notes...</div>;
  }

  return (
    <div ref={containerRef}>
      <div style={styles.header}>
        <button style={styles.newBtn} onClick={onNewNote}>+ New Note</button>
      </div>

      <div style={{fontSize: 11, fontFamily: 'monospace', background: '#f0f0f0', padding: 8, borderRadius: 4, marginBottom: 8}}>
        <div>masonry left-top: 0, 0</div>
        <div>floating left-top: {debugInfo ? `${debugInfo.floatLeft}, ${debugInfo.floatTop}` : '—'}</div>
        <div>closest left-top: {debugInfo ? `${debugInfo.closestLeft}, ${debugInfo.closestTop} — "${debugInfo.closestTitle}" (idx ${debugInfo.closestIdx})` : '—'}</div>
      </div>

      {notes.length === 0 ? (
        <div style={styles.empty}>No notes yet. Create your first note!</div>
      ) : (
        <>
          {/* Hidden measuring layer */}
          <div
            ref={measuringRef}
            style={{
              position: 'absolute',
              visibility: 'hidden',
              width: (() => {
                if (layout) return layout.colWidth;
                if (!containerRef.current) return '50%';
                const w = containerRef.current.offsetWidth;
                const cols = getColumnCount(w);
                return (w - GAP * (cols - 1)) / cols;
              })(),
              left: -9999,
            }}
          >
            {layoutNotes.map(note => (
              note._isHomunculus
                ? <div key="__homunculus__" style={{height: draggingHeightRef.current, marginBottom: 8}} />
                : <NoteCard key={note.id} note={note} onClick={() => {}} />
            ))}
          </div>

          {/* Positioned layout */}
          {layout && (
            <div ref={masonryRef} style={{position: 'relative', height: layout.totalHeight}}>
              {layoutNotes.map((note, i) => {
                const pos = layout.positions[i];
                if (!pos) return null;

                if (note._isHomunculus) {
                  return (
                    <div
                      key="__homunculus__"
                      style={{
                        position: 'absolute',
                        left: pos.left,
                        top: pos.top,
                        width: pos.width,
                        height: draggingHeightRef.current,
                        borderRadius: 8,
                        border: '2px dashed #d1d5db',
                        background: '#f9fafb',
                        transition: 'left 1s, top 1s',
                      }}
                    />
                  );
                }

                const isClosest = closestNoteId && closestNoteId.id === note.id && draggingNoteId !== null;
                const closestOpacity = isClosest
                  ? Math.max(0.3, Math.min(1, closestNoteId.dist / 200))
                  : 1;
                return (
                  <div
                    key={note.id}
                    style={{
                      position: 'absolute',
                      left: pos.left,
                      top: pos.top,
                      width: pos.width,
                      transition: 'left 0.2s, top 0.2s, opacity 0.15s',
                      opacity: closestOpacity,
                    }}
                  >
                    <NoteCard
                      note={note}
                      onClick={() => onSelectNote(note.id)}
                      highlighted={isClosest}
                      onCtrlClick={(e) => {
                        if (draggingNoteId === note.id) {
                          drop();
                        } else {
                          startDrag(note, i, e);
                        }
                      }}
                      dragging={false}
                    />
                  </div>
                );
              })}

              {/* Floating card — inside masonryRef so same coordinate system */}
              {draggingNoteId && dragPos && (() => {
                const dragNote = notes.find(n => n.id === draggingNoteId);
                if (!dragNote) return null;
                return (
                  <div
                    style={{
                      position: 'absolute',
                      left: dragPos.left,
                      top: dragPos.top,
                      width: layout.colWidth,
                      zIndex: 100,
                      opacity: 0.85,
                      cursor: 'grabbing',
                      pointerEvents: 'none',
                    }}
                  >
                    <NoteCard note={dragNote} onClick={() => {}} dragging={true} />
                  </div>
                );
              })()}
            </div>
          )}
        </>
      )}
    </div>
  );
};

const styles = {
  header: {
    display: 'flex',
    justifyContent: 'flex-end',
    marginBottom: 16,
  },
  newBtn: {
    display: 'inline-flex',
    alignItems: 'center',
    gap: 6,
    fontSize: 14,
    fontWeight: 500,
    padding: '10px 20px',
    background: '#fbbc04',
    color: '#202124',
    border: 'none',
    borderRadius: 24,
    cursor: 'pointer',
    boxShadow: '0 1px 2px 0 rgba(60,64,67,0.3), 0 1px 3px 1px rgba(60,64,67,0.15)',
    transition: 'box-shadow 0.15s',
  },
  empty: {
    textAlign: 'center',
    padding: 60,
    color: '#5f6368',
    fontSize: 14,
  },
  loading: {
    textAlign: 'center',
    padding: 40,
    color: '#5f6368',
    fontSize: 14,
  },
};

export default NotesList;
