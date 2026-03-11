import AppKit

// Crop tool implementation is handled in AnnotationRenderer.renderFinalImage
// and AnnotationRenderer.drawCropOverlay.
//
// The crop tool draws a selection rectangle. During final render, the image
// is cropped to the last crop annotation's bounding rect.
