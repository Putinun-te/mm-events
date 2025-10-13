// src/longdo-map.d.ts

declare namespace longdo {
  // 'any' is used here as a simple way to declare the types.
  // You could create more detailed interfaces for better type safety.
  class Map {
    constructor(options: { placeholder: HTMLElement | null, language?: string });
    Overlays: any;
    Layers: any;
  }

  class Marker {
    constructor(location: { lon: number, lat: number }, options?: any);
  }

  const Layers: any;
}