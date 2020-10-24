import React from "react"
import PropTypes from "prop-types"
import DragResizeContainer from 'react-drag-resize';

class GardenLayout extends React.Component {
  onLayoutChange() {
  }
  onclickScreen() {
  }
  render () {
    const layout = [{ key: 'test', x: 0, y: 0, width: 200, height: 100, zIndex: 1 }];
    const canResizable = (isResize) => {
        return { top: isResize, right: isResize, bottom: isResize, left: isResize, topRight: isResize, bottomRight: isResize, bottomLeft: isResize, topLeft: isResize };
    };
    return (
      <section className="garden-layout">
        <h2>Garden Layout</h2>

        <DragResizeContainer
            className='resize-container'
            resizeProps={{
                minWidth: 10,
                minHeight: 10,
                enable: canResizable(isResize)
            }}
            onDoubleClick={onclickScreen}
            layout={layout}
            dragProps={{ disabled: false }}
            onLayoutChange={this.onLayoutChange}
            scale={scale}
        >
          {layout.map((single) => {
            return (
              <div key={single.key} className='child-container size-auto border'>text test</div>
            );
          })}
        </DragResizeContainer>
      </section>
    );
  }
}

export default GardenLayout;
