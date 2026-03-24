import {useState, useRef, useMemo} from 'react';
import {HALF_GAP} from './MasonryLayout';

const findOverlappedNote = (notes, layout, draggingNoteId, dragPos, heightsMap) => {
  const dragHeight = heightsMap[draggingNoteId] || 0;
  const dragWidth = layout.outerColWidth;
  const dragLeft = dragPos.left - HALF_GAP;
  const dragTop = dragPos.top - HALF_GAP;
  const dragRight = dragLeft + dragWidth;
  const dragBottom = dragTop + dragHeight;
  const dragArea = dragWidth * dragHeight;

  let maxOverlap = 0;
  let bestId = null;
  let selfOverlap = 0;
  let totalCardOverlap = 0;

  for (const note of notes) {
    const pos = layout.posMap[note.id];
    if (!pos) continue;

    const activeHeight = Math.min(pos.outerHeight, dragHeight);
    const overlapLeft = Math.max(dragLeft, pos.outerLeft);
    const overlapRight = Math.min(dragRight, pos.outerLeft + pos.outerWidth);
    const overlapTop = Math.max(dragTop, pos.outerTop);
    const overlapBottom = Math.min(dragBottom, pos.outerTop + activeHeight);

    if (overlapRight > overlapLeft && overlapBottom > overlapTop) {
      const area = (overlapRight - overlapLeft) * (overlapBottom - overlapTop);
      totalCardOverlap += area;

      if (note.id === draggingNoteId) {
        selfOverlap = area;
      } else if (area > maxOverlap) {
        maxOverlap = area;
        bestId = note.id;
      }
    }
  }

  const emptyOverlap = dragArea - totalCardOverlap;
  if (maxOverlap > selfOverlap && maxOverlap > emptyOverlap) return bestId;
  return null;
};

export const useDragAndDrop = (notes, layout, heightsMap) => {
  const [draggingNoteId, setDraggingNoteId] = useState(null);
  const [dragPos, setDragPos] = useState(null);
  const dragOffsetRef = useRef({x: 0, y: 0});

  const noteUnderDragged = useMemo(() => {
    if (!layout || !draggingNoteId || !dragPos) return null;
    return findOverlappedNote(notes, layout, draggingNoteId, dragPos, heightsMap || {});
  }, [layout, draggingNoteId, dragPos, notes, heightsMap]);

  const handleMouseMove = (e) => {
    if (!draggingNoteId) return;
    const rect = e.currentTarget.getBoundingClientRect();
    setDragPos({
      left: e.clientX - rect.left - dragOffsetRef.current.x,
      top: e.clientY - rect.top - dragOffsetRef.current.y,
    });
  };

  const startDrag = (note, e, gridRect) => {
    const pos = layout.posMap[note.id];
    dragOffsetRef.current = {
      x: e.clientX - gridRect.left - (pos.outerLeft + HALF_GAP),
      y: e.clientY - gridRect.top - (pos.outerTop + HALF_GAP),
    };
    setDraggingNoteId(note.id);
    setDragPos({left: pos.outerLeft + HALF_GAP, top: pos.outerTop + HALF_GAP});
  };

  const endDrag = () => {
    setDraggingNoteId(null);
    setDragPos(null);
  };

  return {draggingNoteId, dragPos, noteUnderDragged, handleMouseMove, startDrag, endDrag};
};
