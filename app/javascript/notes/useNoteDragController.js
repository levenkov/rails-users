export const useNoteDragController = (notes) => {
  const onDragStart = (e, noteId) => {
    e.dataTransfer.setData('text/plain', noteId);
  };

  return {onDragStart};
};
