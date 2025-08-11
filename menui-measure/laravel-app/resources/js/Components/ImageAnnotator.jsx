import React, { useState, useRef, useEffect } from 'react';
import { Stage, Layer, Image, Line, Circle, Text, Group } from 'react-konva';
import { Ruler, Square, Undo, Redo, Save, MousePointer } from 'lucide-react';
import useImage from 'use-image';

const ImageAnnotator = ({ 
    imageUrl, 
    onSave, 
    suggestions = [], 
    pixelsPerMm = null,
    initialPoints = null 
}) => {
    const [image] = useImage(imageUrl);
    const [tool, setTool] = useState('pointer'); // 'pointer', 'polygon', 'line'
    const [points, setPoints] = useState([]);
    const [currentPolygon, setCurrentPolygon] = useState([]);
    const [lines, setLines] = useState([]);
    const [currentLine, setCurrentLine] = useState([]);
    const [history, setHistory] = useState([]);
    const [historyStep, setHistoryStep] = useState(0);
    const [stageSize, setStageSize] = useState({ width: 800, height: 600 });
    const [scale, setScale] = useState(1);
    const stageRef = useRef();
    const containerRef = useRef();

    // Adapter la taille du stage à l'image
    useEffect(() => {
        if (image && containerRef.current) {
            const containerWidth = containerRef.current.offsetWidth;
            const scale = containerWidth / image.width;
            setScale(scale);
            setStageSize({
                width: containerWidth,
                height: image.height * scale
            });
        }
    }, [image]);

    // Charger les points initiaux si fournis
    useEffect(() => {
        if (initialPoints) {
            if (initialPoints.type === 'polygon') {
                setCurrentPolygon(initialPoints.points);
            } else if (initialPoints.type === 'line') {
                setCurrentLine(initialPoints.points);
            }
        }
    }, [initialPoints]);

    const handleStageClick = (e) => {
        if (tool === 'pointer') return;

        const stage = e.target.getStage();
        const point = stage.getPointerPosition();
        const scaledPoint = {
            x: point.x / scale,
            y: point.y / scale
        };

        if (tool === 'polygon') {
            const newPolygon = [...currentPolygon, scaledPoint];
            setCurrentPolygon(newPolygon);
            addToHistory({ type: 'polygon', points: newPolygon });
        } else if (tool === 'line' && currentLine.length < 2) {
            const newLine = [...currentLine, scaledPoint];
            setCurrentLine(newLine);
            if (newLine.length === 2) {
                addToHistory({ type: 'line', points: newLine });
            }
        }
    };

    const addToHistory = (action) => {
        const newHistory = history.slice(0, historyStep + 1);
        newHistory.push(action);
        setHistory(newHistory);
        setHistoryStep(newHistory.length - 1);
    };

    const undo = () => {
        if (historyStep > 0) {
            setHistoryStep(historyStep - 1);
            applyHistoryState(history[historyStep - 1]);
        } else {
            // Effacer tout si on est au début
            setCurrentPolygon([]);
            setCurrentLine([]);
        }
    };

    const redo = () => {
        if (historyStep < history.length - 1) {
            setHistoryStep(historyStep + 1);
            applyHistoryState(history[historyStep + 1]);
        }
    };

    const applyHistoryState = (state) => {
        if (state.type === 'polygon') {
            setCurrentPolygon(state.points);
            setCurrentLine([]);
        } else if (state.type === 'line') {
            setCurrentLine(state.points);
            setCurrentPolygon([]);
        }
    };

    const completePolygon = () => {
        if (currentPolygon.length >= 3) {
            setPoints([...points, currentPolygon]);
            setCurrentPolygon([]);
        }
    };

    const clearAll = () => {
        setCurrentPolygon([]);
        setCurrentLine([]);
        setPoints([]);
        setLines([]);
        setHistory([]);
        setHistoryStep(0);
    };

    const calculateDistance = (p1, p2) => {
        const dx = p2.x - p1.x;
        const dy = p2.y - p1.y;
        return Math.sqrt(dx * dx + dy * dy);
    };

    const calculateArea = (polygon) => {
        let area = 0;
        for (let i = 0; i < polygon.length; i++) {
            const j = (i + 1) % polygon.length;
            area += polygon[i].x * polygon[j].y;
            area -= polygon[j].x * polygon[i].y;
        }
        return Math.abs(area / 2);
    };

    const handleSave = () => {
        let measurementData = null;

        if (currentPolygon.length >= 3) {
            const areaPx = calculateArea(currentPolygon);
            const areaMm2 = pixelsPerMm ? areaPx / (pixelsPerMm * pixelsPerMm) : null;
            measurementData = {
                type: 'area',
                points: currentPolygon,
                area_px: areaPx,
                area_mm2: areaMm2,
                area_m2: areaMm2 ? areaMm2 / 1000000 : null
            };
        } else if (currentLine.length === 2) {
            const distancePx = calculateDistance(currentLine[0], currentLine[1]);
            const distanceMm = pixelsPerMm ? distancePx / pixelsPerMm : null;
            measurementData = {
                type: 'length',
                points: currentLine,
                distance_px: distancePx,
                distance_mm: distanceMm,
                distance_m: distanceMm ? distanceMm / 1000 : null
            };
        }

        if (measurementData && onSave) {
            onSave(measurementData);
        }
    };

    const renderMeasurementInfo = () => {
        if (currentPolygon.length >= 3 && pixelsPerMm) {
            const areaPx = calculateArea(currentPolygon);
            const areaM2 = areaPx / (pixelsPerMm * pixelsPerMm) / 1000000;
            return (
                <div className="bg-blue-50 border border-blue-200 rounded p-3">
                    <p className="text-sm font-medium text-blue-900">
                        Surface: {areaM2.toFixed(2)} m²
                    </p>
                </div>
            );
        } else if (currentLine.length === 2 && pixelsPerMm) {
            const distancePx = calculateDistance(currentLine[0], currentLine[1]);
            const distanceM = distancePx / pixelsPerMm / 1000;
            return (
                <div className="bg-blue-50 border border-blue-200 rounded p-3">
                    <p className="text-sm font-medium text-blue-900">
                        Longueur: {distanceM.toFixed(2)} m
                    </p>
                </div>
            );
        }
        return null;
    };

    return (
        <div className="space-y-4">
            {/* Barre d'outils */}
            <div className="bg-white rounded-lg shadow p-4">
                <div className="flex items-center justify-between">
                    <div className="flex space-x-2">
                        <button
                            onClick={() => setTool('pointer')}
                            className={`p-2 rounded ${tool === 'pointer' ? 'bg-blue-100 text-blue-600' : 'bg-gray-100'}`}
                            title="Sélection"
                        >
                            <MousePointer className="w-5 h-5" />
                        </button>
                        <button
                            onClick={() => setTool('line')}
                            className={`p-2 rounded ${tool === 'line' ? 'bg-blue-100 text-blue-600' : 'bg-gray-100'}`}
                            title="Mesurer une longueur"
                        >
                            <Ruler className="w-5 h-5" />
                        </button>
                        <button
                            onClick={() => setTool('polygon')}
                            className={`p-2 rounded ${tool === 'polygon' ? 'bg-blue-100 text-blue-600' : 'bg-gray-100'}`}
                            title="Mesurer une surface"
                        >
                            <Square className="w-5 h-5" />
                        </button>
                        
                        <div className="border-l mx-2" />
                        
                        <button
                            onClick={undo}
                            className="p-2 rounded bg-gray-100 hover:bg-gray-200 disabled:opacity-50"
                            disabled={historyStep === 0 && currentPolygon.length === 0 && currentLine.length === 0}
                            title="Annuler"
                        >
                            <Undo className="w-5 h-5" />
                        </button>
                        <button
                            onClick={redo}
                            className="p-2 rounded bg-gray-100 hover:bg-gray-200 disabled:opacity-50"
                            disabled={historyStep >= history.length - 1}
                            title="Refaire"
                        >
                            <Redo className="w-5 h-5" />
                        </button>
                    </div>

                    <div className="flex items-center space-x-2">
                        {tool === 'polygon' && currentPolygon.length >= 3 && (
                            <button
                                onClick={completePolygon}
                                className="px-3 py-1 text-sm bg-green-500 text-white rounded hover:bg-green-600"
                            >
                                Fermer le polygone
                            </button>
                        )}
                        <button
                            onClick={clearAll}
                            className="px-3 py-1 text-sm bg-gray-500 text-white rounded hover:bg-gray-600"
                        >
                            Effacer tout
                        </button>
                        <button
                            onClick={handleSave}
                            className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 flex items-center space-x-2"
                            disabled={currentPolygon.length < 3 && currentLine.length !== 2}
                        >
                            <Save className="w-4 h-4" />
                            <span>Enregistrer la mesure</span>
                        </button>
                    </div>
                </div>

                {/* Instructions */}
                <div className="mt-3 text-sm text-gray-600">
                    {tool === 'line' && (
                        <p>Cliquez sur deux points pour mesurer une distance</p>
                    )}
                    {tool === 'polygon' && (
                        <p>Cliquez pour ajouter des points et former une surface. Minimum 3 points.</p>
                    )}
                </div>
            </div>

            {/* Zone de dessin */}
            <div ref={containerRef} className="bg-gray-100 rounded-lg overflow-hidden">
                <Stage
                    ref={stageRef}
                    width={stageSize.width}
                    height={stageSize.height}
                    onClick={handleStageClick}
                    className="cursor-crosshair"
                >
                    <Layer>
                        {/* Image de fond */}
                        {image && (
                            <Image
                                image={image}
                                width={stageSize.width}
                                height={stageSize.height}
                            />
                        )}

                        {/* Suggestions (affichées en gris) */}
                        {suggestions.map((suggestion, idx) => (
                            <Line
                                key={`suggestion-${idx}`}
                                points={suggestion.mask_poly.flat().map((val, i) => 
                                    i % 2 === 0 ? val * scale : val * scale
                                )}
                                stroke="gray"
                                strokeWidth={1}
                                opacity={0.5}
                                closed={suggestion.type === 'area'}
                                dash={[5, 5]}
                            />
                        ))}

                        {/* Polygone en cours */}
                        {currentPolygon.length > 0 && (
                            <>
                                <Line
                                    points={currentPolygon.flatMap(p => [p.x * scale, p.y * scale])}
                                    stroke="blue"
                                    strokeWidth={2}
                                    closed={false}
                                />
                                {currentPolygon.map((point, idx) => (
                                    <Circle
                                        key={`poly-point-${idx}`}
                                        x={point.x * scale}
                                        y={point.y * scale}
                                        radius={5}
                                        fill="blue"
                                    />
                                ))}
                            </>
                        )}

                        {/* Ligne en cours */}
                        {currentLine.length > 0 && (
                            <>
                                {currentLine.length === 2 && (
                                    <Line
                                        points={currentLine.flatMap(p => [p.x * scale, p.y * scale])}
                                        stroke="red"
                                        strokeWidth={2}
                                    />
                                )}
                                {currentLine.map((point, idx) => (
                                    <Circle
                                        key={`line-point-${idx}`}
                                        x={point.x * scale}
                                        y={point.y * scale}
                                        radius={5}
                                        fill="red"
                                    />
                                ))}
                            </>
                        )}
                    </Layer>
                </Stage>
            </div>

            {/* Affichage des mesures */}
            {renderMeasurementInfo()}
        </div>
    );
};

export default ImageAnnotator;