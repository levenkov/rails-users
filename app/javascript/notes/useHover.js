import {useState, useCallback} from 'react';

export const useHover = () => {
  const [isHover, setIsHover] = useState(false);

  const hoverProps = {
    onMouseEnter: useCallback(() => setIsHover(true), []),
    onMouseLeave: useCallback(() => setIsHover(false), []),
  };

  return [isHover, hoverProps];
};
