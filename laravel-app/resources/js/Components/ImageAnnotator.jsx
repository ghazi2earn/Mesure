import { useState, useRef, useCallback } from 'react';
import { Stage, Layer, Image as KonvaImage, Line, Circle, Text } from 'react-konva';
import useImage from 'use-image';

const TOOL_MODES = {
    POLYGON: 'polygon',
    TWO_POINTS: 'two_points',
    VIEW: 'view'
};

function ImageComponent({ src, onLoad }) {
    const [image] = useImage(src);
    
    if (image && onLoad) {
        onLoad(image);
    }
    
    return image ? <KonvaImage image={image} /> : null;
}

export default function ImageAnnotator({ 
    imageSrc, 
    initialPoints = [], 
    onSaveMeasurement,
    pixelsPerMm = null,
    detectedMarker = null 
}) {
    const [tool, setTool] = useState(TOOL_MODES.VIEW);
    const [points, setPoints] = useState(initialPoints);
    const [polygonPoints, setPolygonPoints] = useState([]);
    const [twoPoints, setTwoPoints] = useState([]);
    const [imageSize, setImageSize] = useState({ width: 0, height: 0 });
    const [stageSize, setStageSize] = useState({ width: 800, height: 600 });
    const [scale, setScale] = useState(1);
    const stageRef = useRef();

    const handleImageLoad = useCallback((image) => {
        const maxWidth = 800;
        const maxHeight = 600;
        
        const imageWidth = image.width;
        const imageHeight = image.height;
        
        // Calculer l'échelle pour adapter l'image
        const scaleX = maxWidth / imageWidth;
        const scaleY = maxHeight / imageHeight;
        const newScale = Math.min(scaleX, scaleY, 1);
        
        setScale(newScale);
        setImageSize({ width: imageWidth, height: imageHeight });
        setStageSize({ 
            width: imageWidth * newScale, 
            height: imageHeight * newScale 
        });
    }, []);

    const handleStageClick = (e) => {
        if (tool === TOOL_MODES.VIEW) return;

        const pos = e.target.getStage().getPointerPosition();
        const realPos = {
            x: pos.x / scale,
            y: pos.y / scale
        };

        if (tool === TOOL_MODES.POLYGON) {
            setPolygonPoints([...polygonPoints, realPos.x, realPos.y]);
        } else if (tool === TOOL_MODES.TWO_POINTS) {
            if (twoPoints.length < 4) {
                setTwoPoints([...twoPoints, realPos.x, realPos.y]);
            }
        }
    };

    const finishPolygon = () => {
        if (polygonPoints.length >= 6) { // Au moins 3 points
            setPoints([...points, { type: 'polygon', points: [...polygonPoints] }]);
            setPolygonPoints([]);
            setTool(TOOL_MODES.VIEW);
        }
    };

    const finishTwoPoints = () => {
        if (twoPoints.length === 4) {
            setPoints([...points, { type: 'distance', points: [...twoPoints] }]);
            setTwoPoints([]);
            setTool(TOOL_MODES.VIEW);
        }
    };

    const calculateDistance = (points) => {
        if (points.length !== 4) return 0;
        const dx = points[2] - points[0];
        const dy = points[3] - points[1];
        const distancePixels = Math.sqrt(dx * dx + dy * dy);
        return pixelsPerMm ? distancePixels / pixelsPerMm : distancePixels;
    };

    const calculateArea = (points) => {
        if (points.length < 6) return 0;
        
        // Algorithme du lacet pour calculer l'aire
        let area = 0;
        for (let i = 0; i < points.length - 2; i += 2) {
            const x1 = points[i];
            const y1 = points[i + 1];
            const x2 = points[(i + 2) % points.length];
            const y2 = points[(i + 3) % points.length];
            area += x1 * y2 - x2 * y1;
        }
        area = Math.abs(area) / 2;
        
        return pixelsPerMm ? area / (pixelsPerMm * pixelsPerMm) : area;
    };

    const undoLastAction = () => {
        if (polygonPoints.length > 0) {
            setPolygonPoints(polygonPoints.slice(0, -2));
        } else if (twoPoints.length > 0) {
            setTwoPoints(twoPoints.slice(0, -2));
        } else if (points.length > 0) {
            setPoints(points.slice(0, -1));
        }
    };

    const clearAll = () => {
        setPoints([]);
        setPolygonPoints([]);
        setTwoPoints([]);
        setTool(TOOL_MODES.VIEW);
    };

    const saveMeasurement = () => {
        const measurements = points.map(point => {
            if (point.type === 'polygon') {
                return {
                    type: 'area',
                    points: point.points,
                    value_mm2: calculateArea(point.points),
                    value_m2: calculateArea(point.points) / 1000000
                };
            } else if (point.type === 'distance') {
                return {
                    type: 'length',
                    points: point.points,
                    value_mm: calculateDistance(point.points)
                };
            }
        });

        if (onSaveMeasurement) {
            onSaveMeasurement(measurements);
        }
    };

    return (
        <div className="space-y-4">
            {/* Barre d'outils */}
            <div className="flex items-center justify-between p-4 bg-white rounded-lg shadow">
                <div className="flex space-x-2">
                    <button
                        onClick={() => setTool(TOOL_MODES.VIEW)}
                        className={`px-3 py-2 text-sm font-medium rounded-md ${
                            tool === TOOL_MODES.VIEW 
                                ? 'bg-indigo-600 text-white' 
                                : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                        }`}
                    >
                        👁️ Visualiser
                    </button>
                    <button
                        onClick={() => setTool(TOOL_MODES.POLYGON)}
                        className={`px-3 py-2 text-sm font-medium rounded-md ${
                            tool === TOOL_MODES.POLYGON 
                                ? 'bg-indigo-600 text-white' 
                                : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                        }`}
                    >
                        📐 Surface
                    </button>
                    <button
                        onClick={() => setTool(TOOL_MODES.TWO_POINTS)}
                        className={`px-3 py-2 text-sm font-medium rounded-md ${
                            tool === TOOL_MODES.TWO_POINTS 
                                ? 'bg-indigo-600 text-white' 
                                : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                        }`}
                    >
                        📏 Distance
                    </button>
                </div>

                <div className="flex space-x-2">
                    {tool === TOOL_MODES.POLYGON && polygonPoints.length >= 6 && (
                        <button
                            onClick={finishPolygon}
                            className="px-3 py-2 text-sm font-medium text-white bg-green-600 rounded-md hover:bg-green-700"
                        >
                            Terminer polygone
                        </button>
                    )}
                    {tool === TOOL_MODES.TWO_POINTS && twoPoints.length === 4 && (
                        <button
                            onClick={finishTwoPoints}
                            className="px-3 py-2 text-sm font-medium text-white bg-green-600 rounded-md hover:bg-green-700"
                        >
                            Terminer distance
                        </button>
                    )}
                    <button
                        onClick={undoLastAction}
                        className="px-3 py-2 text-sm font-medium text-gray-700 bg-gray-200 rounded-md hover:bg-gray-300"
                    >
                        ↶ Annuler
                    </button>
                    <button
                        onClick={clearAll}
                        className="px-3 py-2 text-sm font-medium text-white bg-red-600 rounded-md hover:bg-red-700"
                    >
                        🗑️ Effacer tout
                    </button>
                    {points.length > 0 && (
                        <button
                            onClick={saveMeasurement}
                            className="px-4 py-2 text-sm font-medium text-white bg-indigo-600 rounded-md hover:bg-indigo-700"
                        >
                            💾 Sauvegarder
                        </button>
                    )}
                </div>
            </div>

            {/* Zone de dessin */}
            <div className="bg-white rounded-lg shadow p-4">
                <Stage
                    width={stageSize.width}
                    height={stageSize.height}
                    onClick={handleStageClick}
                    ref={stageRef}
                    scaleX={scale}
                    scaleY={scale}
                >
                    <Layer>
                        {/* Image */}
                        <ImageComponent src={imageSrc} onLoad={handleImageLoad} />
                        
                        {/* Marqueur A4 détecté */}
                        {detectedMarker && detectedMarker.corners && (
                            <>
                                <Line
                                    points={detectedMarker.corners.flat()}
                                    closed
                                    stroke="green"
                                    strokeWidth={3}
                                />
                                <Text
                                    x={detectedMarker.corners[0][0]}
                                    y={detectedMarker.corners[0][1] - 20}
                                    text="A4 détecté"
                                    fontSize={16}
                                    fill="green"
                                />
                            </>
                        )}
                        
                        {/* Polygones et distances sauvegardés */}
                        {points.map((point, index) => (
                            <g key={index}>
                                {point.type === 'polygon' && (
                                    <>
                                        <Line
                                            points={point.points}
                                            closed
                                            stroke="blue"
                                            strokeWidth={2}
                                            fill="rgba(0, 0, 255, 0.1)"
                                        />
                                        <Text
                                            x={point.points[0]}
                                            y={point.points[1] - 20}
                                            text={`${(calculateArea(point.points) / 1000000).toFixed(3)} m²`}
                                            fontSize={14}
                                            fill="blue"
                                        />
                                    </>
                                )}
                                {point.type === 'distance' && (
                                    <>
                                        <Line
                                            points={point.points}
                                            stroke="red"
                                            strokeWidth={2}
                                        />
                                        <Circle
                                            x={point.points[0]}
                                            y={point.points[1]}
                                            radius={4}
                                            fill="red"
                                        />
                                        <Circle
                                            x={point.points[2]}
                                            y={point.points[3]}
                                            radius={4}
                                            fill="red"
                                        />
                                        <Text
                                            x={(point.points[0] + point.points[2]) / 2}
                                            y={(point.points[1] + point.points[3]) / 2 - 10}
                                            text={`${(calculateDistance(point.points) / 1000).toFixed(2)} m`}
                                            fontSize={14}
                                            fill="red"
                                        />
                                    </>
                                )}
                            </g>
                        ))}
                        
                        {/* Polygone en cours */}
                        {polygonPoints.length > 0 && (
                            <>
                                <Line
                                    points={polygonPoints}
                                    stroke="blue"
                                    strokeWidth={2}
                                    dash={[5, 5]}
                                />
                                {/* Points du polygone */}
                                {Array.from({ length: polygonPoints.length / 2 }).map((_, i) => (
                                    <Circle
                                        key={i}
                                        x={polygonPoints[i * 2]}
                                        y={polygonPoints[i * 2 + 1]}
                                        radius={4}
                                        fill="blue"
                                    />
                                ))}
                            </>
                        )}
                        
                        {/* Distance en cours */}
                        {twoPoints.length > 0 && (
                            <>
                                <Line
                                    points={twoPoints}
                                    stroke="red"
                                    strokeWidth={2}
                                    dash={[5, 5]}
                                />
                                {Array.from({ length: twoPoints.length / 2 }).map((_, i) => (
                                    <Circle
                                        key={i}
                                        x={twoPoints[i * 2]}
                                        y={twoPoints[i * 2 + 1]}
                                        radius={4}
                                        fill="red"
                                    />
                                ))}
                            </>
                        )}
                    </Layer>
                </Stage>
            </div>

            {/* Instructions */}
            <div className="bg-gray-50 rounded-lg p-4">
                <h3 className="text-sm font-medium text-gray-900 mb-2">Instructions:</h3>
                <div className="text-sm text-gray-600 space-y-1">
                    {tool === TOOL_MODES.VIEW && (
                        <p>Sélectionnez un outil pour commencer à mesurer.</p>
                    )}
                    {tool === TOOL_MODES.POLYGON && (
                        <p>Cliquez pour ajouter des points au polygone. Cliquez sur "Terminer polygone" quand vous avez fini.</p>
                    )}
                    {tool === TOOL_MODES.TWO_POINTS && (
                        <p>Cliquez sur deux points pour mesurer la distance entre eux.</p>
                    )}
                </div>
                
                {pixelsPerMm && (
                    <div className="mt-2 text-xs text-gray-500">
                        Échelle: {pixelsPerMm.toFixed(2)} pixels/mm
                    </div>
                )}
            </div>

            {/* Résultats */}
            {points.length > 0 && (
                <div className="bg-white rounded-lg shadow p-4">
                    <h3 className="text-lg font-medium text-gray-900 mb-4">Mesures</h3>
                    <div className="space-y-2">
                        {points.map((point, index) => (
                            <div key={index} className="flex justify-between items-center p-2 bg-gray-50 rounded">
                                <span className="text-sm text-gray-600">
                                    {point.type === 'polygon' ? 'Surface' : 'Distance'} #{index + 1}
                                </span>
                                <span className="text-sm font-medium">
                                    {point.type === 'polygon' 
                                        ? `${(calculateArea(point.points) / 1000000).toFixed(3)} m²`
                                        : `${(calculateDistance(point.points) / 1000).toFixed(2)} m`
                                    }
                                </span>
                            </div>
                        ))}
                    </div>
                </div>
            )}
        </div>
    );
}