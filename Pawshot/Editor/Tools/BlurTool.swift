import AppKit

// Blur/Mosaic tool implementation is handled in AnnotationRenderer.applyBlur
// using CIFilter's CIPixellate filter.
//
// The blur tool creates a rectangular selection area. During final render,
// the selected area is pixellated using CIPixellate with a scale proportional
// to the line width setting.
