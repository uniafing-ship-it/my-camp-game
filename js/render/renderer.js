export class RendererBoundary {
  constructor(root = document) { this.root = root; }
  refresh() { this.root.documentElement?.setAttribute('data-renderer-ready', '1'); }
}
