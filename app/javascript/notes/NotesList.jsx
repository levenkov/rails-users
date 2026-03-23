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
  const [draggingNoteId, setDraggingNoteId] = useState(null);
  const [dragPos, setDragPos] = useState(null);
  const [homunculusIndex, setHomunculusIndex] = useState(null);
  const [debugInfo, setDebugInfo] = useState(null);
  const [closestNoteId, setClosestNoteId] = useState(null);
  const [heightsReady, setHeightsReady] = useState(false);

  const containerRef = useRef(null);
  const masonryRef = useRef(null);
  const heightsMap = useRef({});
  const dragOffsetRef = useRef({x: 0, y: 0});
  const dragThrottleRef = useRef(null);
  const draggingHeightRef = useRef(0);

  const fetchNotes = async () => {
    setLoading(true);
    const data = await api.get('/notes.json');
    setNotes(data);
    setHeightsReady(false);
    setLoading(false);
  };

  useEffect(() => {
    fetchNotes();
  }, []);

  // Measure all cards once after they render
  useEffect(() => {
    if (heightsReady || notes.length === 0 || !masonryRef.current) return;

    requestAnimationFrame(() => {
      const cards = masonryRef.current?.children;
      if (!cards) return;

      for (let i = 0; i < cards.length; i++) {
        const noteId = notes[i]?.id;
        if (noteId && !heightsMap.current[noteId]) {
          heightsMap.current[noteId] = cards[i].offsetHeight;
        }
      }

      setHeightsReady(true);
    });
  }, [notes, heightsReady]);

  // Build layoutNotes with homunculus
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

  // Compute layout synchronously from cached heights
  const layout = useMemo(() => {
    if (!containerRef.current || layoutNotes.length === 0 || !heightsReady) return null;

    console.log('layout useMemo recalc, homunculusIndex:', homunculusIndex, 'draggingNoteId:', draggingNoteId);

    const containerWidth = containerRef.current.offsetWidth;
    const colCount = getColumnCount(containerWidth);
    const colWidth = (containerWidth - GAP * (colCount - 1)) / colCount;

    const colHeights = new Array(colCount).fill(0);
    const posMap = {};

    for (let i = 0; i < layoutNotes.length; i++) {
      const note = layoutNotes[i];
      const noteKey = note.id || '__homunculus__';
      const height = note._isHomunculus
        ? draggingHeightRef.current
        : (heightsMap.current[noteKey] || 0);

      let minCol = 0;
      for (let c = 1; c < colCount; c++) {
        if (colHeights[c] < colHeights[minCol]) {
          minCol = c;
        }
      }

      posMap[noteKey] = {
        left: minCol * (colWidth + GAP),
        top: colHeights[minCol],
      };

      colHeights[minCol] += height + GAP;
    }

    const totalHeight = Math.max(...colHeights, 0);
    return {posMap, totalHeight, colWidth};
  }, [layoutNotes, heightsReady]);

  // Re-measure on resize
  useEffect(() => {
    const handleResize = () => {
      heightsMap.current = {};
      setHeightsReady(false);
    };
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  // Determine target index from floating card's left-top position
  const computeIndexFromPosition = useCallback((floatLeft, floatTop) => {
    if (!layout || !layoutNotes.length) return 0;

    const items = [];
    let indexInOthers = 0;
    layoutNotes.forEach((n) => {
      if (n._isHomunculus) return;
      if (n.id === draggingNoteId) return;
      const itemPos = layout.posMap[n.id];
      if (itemPos) {
        items.push({
          index: indexInOthers,
          left: itemPos.left,
          top: itemPos.top,
          id: n.id,
          title: n.title,
        });
      }
      indexInOthers++;
    });

    if (items.length === 0) return 0;

    const dists = items.map((item) => {
      const dx = floatLeft - item.left;
      const dy = floatTop - item.top;
      return {index: item.index, dist: Math.sqrt(dx * dx + dy * dy), item};
    });
    dists.sort((a, b) => a.dist - b.dist);

    const closest = dists[0];
    const secondClosest = dists.length > 1 ? dists[1] : null;

    setDebugInfo({
      floatLeft: Math.round(floatLeft),
      floatTop: Math.round(floatTop),
      closestLeft: Math.round(closest.item.left),
      closestTop: Math.round(closest.item.top),
      closestTitle: closest.item.title || '(untitled)',
      closestIdx: closest.index,
    });
    setClosestNoteId({id: closest.item.id, dist: closest.dist});

    const passes5x = !secondClosest || closest.dist * 5 < secondClosest.dist;
    console.log('5x check:', 'closest dist:', Math.round(closest.dist), 'second dist:', secondClosest ? Math.round(secondClosest.dist) : 'none', 'passes:', passes5x, 'returning:', passes5x ? closest.index : homunculusIndex);

    if (passes5x) {
      return closest.index;
    }

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

      if (!dragThrottleRef.current) {
        dragThrottleRef.current = setTimeout(() => {
          dragThrottleRef.current = null;
          const newIndex = computeIndexFromPosition(newLeft, newTop);
          console.log('throttle: newIndex', newIndex, 'current homunculusIndex', homunculusIndex);
          setHomunculusIndex(prev => {
            if (prev === newIndex) return prev;
            console.log('setHomunculusIndex:', prev, '→', newIndex);
            return newIndex;
          });
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
  const startDrag = (note, e) => {
    const masonryRect = masonryRef.current.getBoundingClientRect();
    const cardPos = layout.posMap[note.id];
    dragOffsetRef.current = {
      x: e.clientX - masonryRect.left - cardPos.left,
      y: e.clientY - masonryRect.top - cardPos.top,
    };
    draggingHeightRef.current = heightsMap.current[note.id] || 50;
    const noteIndex = notes.findIndex(n => n.id === note.id);
    setHomunculusIndex(noteIndex);
    setDraggingNoteId(note.id);
    setDragPos({left: cardPos.left, top: cardPos.top});
  };

  // Drop
  const drop = async () => {
    if (!draggingNoteId || homunculusIndex === null) return;

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

  const colWidth = layout ? layout.colWidth : 200;

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
        <div ref={masonryRef} style={{position: 'relative', height: layout ? layout.totalHeight : 'auto', overflow: 'hidden'}}>
          {layoutNotes.map((note) => {
            const noteKey = note.id || '__homunculus__';
            const pos = layout ? layout.posMap[noteKey] : null;
            const left = pos ? pos.left : -9999;
            const top = pos ? pos.top : 0;

            if (note._isHomunculus) {
              return (
                <div
                  key="__homunculus__"
                  style={{
                    position: 'absolute',
                    left,
                    top,
                    width: colWidth,
                    height: draggingHeightRef.current,
                    borderRadius: 8,
                    border: '2px dashed #d1d5db',
                    background: '#f9fafb',
                    transition: 'all 1s',
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
                  left,
                  top,
                  width: colWidth,
                  transition: 'all 1s',
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
                      startDrag(note, e);
                    }
                  }}
                  dragging={false}
                />
              </div>
            );
          })}

          {/* Floating card */}
          {draggingNoteId && dragPos && (() => {
            const dragNote = notes.find(n => n.id === draggingNoteId);
            if (!dragNote) return null;
            return (
              <div
                style={{
                  position: 'absolute',
                  left: dragPos.left,
                  top: dragPos.top,
                  width: colWidth,
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
    transition: 'all 1s',
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
