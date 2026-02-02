declare module 'react-map-gl' {
  export interface ViewState {
    longitude: number;
    latitude: number;
    zoom: number;
    bearing?: number;
    pitch?: number;
  }

  export interface MapProps {
    mapboxAccessToken: string;
    initialViewState?: ViewState;
    viewState?: ViewState;
    onMove?: (event: { viewState: ViewState }) => void;
    style?: React.CSSProperties;
    mapStyle?: string;
    children?: React.ReactNode;
  }

  export interface MarkerProps {
    longitude: number;
    latitude: number;
    anchor?: string;
    onClick?: () => void;
    children?: React.ReactNode;
  }

  export interface PopupProps {
    longitude: number;
    latitude: number;
    onClose?: () => void;
    closeButton?: boolean;
    closeOnClick?: boolean;
    children?: React.ReactNode;
  }

  export const Map: React.FC<MapProps>;
  export const Marker: React.FC<MarkerProps>;
  export const Popup: React.FC<PopupProps>;
}

