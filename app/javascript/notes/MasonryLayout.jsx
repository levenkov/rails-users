import React, {useMemo} from 'react';

const GAP = 8;
const HALF_GAP = GAP / 2;

const getColumnCount = (width) => {
  if (width >= 1200) return 5;
  if (width >= 900) return 4;
  if (width >= 600) return 3;
  return 2;
};

const computePositions = (items, containerWidth) => {
  const colCount = getColumnCount(containerWidth);
  const outerColWidth = containerWidth / colCount;
  const innerColWidth = outerColWidth - GAP;
  const colHeights = new Array(colCount).fill(0);
  const notePositions = {};

  for (const {id, height} of items) {
    const outerHeight = (height || 0) + GAP;
    let minCol = 0;
    for (let c = 1; c < colCount; c++) {
      if (colHeights[c] < colHeights[minCol]) minCol = c;
    }
    notePositions[id] = {
      outerLeft: minCol * outerColWidth,
      outerTop: colHeights[minCol],
      outerWidth: outerColWidth,
      outerHeight,
    };
    colHeights[minCol] += outerHeight;
  }

  return {
    notePositions,
    totalHeight: Math.max(...colHeights, 0),
    outerColWidth,
    innerColWidth,
  };
};

const defaultKeyExtractor = (item) => item.id;

const MasonryLayout = ({
  data,
  heightsMap,
  width,
  renderItem,
  keyExtractor = defaultKeyExtractor,
}) => {
  const layout = useMemo(() => {
    if (
      !width ||
      data.length === 0 ||
      !checkAllNotesMeasured(data, heightsMap, keyExtractor)
    ) return null;

    const items = data.map(item => ({
      id: keyExtractor(item),
      height: heightsMap[keyExtractor(item)],
    }));
    return computePositions(items, width);
  }, [data, heightsMap, width]);

  return (
    <div style={{...styles.grid, height: layout ? layout.totalHeight : 'auto'}}>
      {
        data.map((item) => {
          const key = keyExtractor(item);
          const pos = layout ? layout.notePositions[key] : null;
          return (
            <div
              key={key}
              style={{
                ...styles.cell,
                left: pos ? pos.outerLeft + HALF_GAP : -9999,
                top: pos ? pos.outerTop + HALF_GAP : 0,
                width: pos ? pos.outerWidth - GAP : '25%',
              }}
            >
              {renderItem({item})}
            </div>
          );
        })
      }
    </div>
  );
};

const checkAllNotesMeasured = (data, heightsMap, keyExtractor) =>
  data.length > 0 && data.every(item => heightsMap[keyExtractor(item)] != null);

const styles = {
  grid: {
    position: 'relative',
    overflow: 'hidden',
  },
  cell: {
    position: 'absolute',
    transition: 'left 0.5s, top 0.5s',
    boxSizing: 'border-box',
  },
};

export {GAP, HALF_GAP};
export default MasonryLayout;
