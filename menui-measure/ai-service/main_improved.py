from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from typing import List, Optional, Dict, Any, Tuple
import cv2
import numpy as np
import json
import os
import uuid
from datetime import datetime
import aiofiles
from pathlib import Path

app = FastAPI(title="Service IA de Mesure Menui - Version Améliorée", version="1.1.0")

# Configuration
if os.name == 'nt':  # Windows
    BASE_DIR = Path(__file__).parent
    UPLOAD_DIR = BASE_DIR / "uploads"
    PROCESSED_DIR = BASE_DIR / "processed"
    DEBUG_DIR = BASE_DIR / "debug"
else:  # Docker/Linux
    UPLOAD_DIR = Path("/app/uploads")
    PROCESSED_DIR = Path("/app/processed")
    DEBUG_DIR = Path("/app/debug")

UPLOAD_DIR.mkdir(exist_ok=True)
PROCESSED_DIR.mkdir(exist_ok=True)
DEBUG_DIR.mkdir(exist_ok=True)

# Models
class MeasurementSuggestion(BaseModel):
    mask_poly: List[List[float]]
    confidence: float
    type: str

class AnalyzeResponse(BaseModel):
    marker: Optional[Dict[str, Any]]
    pixels_per_mm: Optional[float]
    suggestions: List[MeasurementSuggestion]
    preliminary_measurements: List[Dict[str, Any]]
    annotated_image_url: str
    success: bool
    message: str
    debug_info: Optional[Dict[str, Any]] = None

def detect_a4_marker_robust(image: np.ndarray, debug_path: Optional[str] = None) -> Optional[Tuple[np.ndarray, float]]:
    """
    Version robuste de la détection A4 avec multiple stratégies.
    """
    debug_info = {}
    
    # Convertir en niveaux de gris
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    
    if debug_path:
        cv2.imwrite(f"{debug_path}_1_gray.jpg", gray)
    
    # Stratégie 1: Détection standard avec paramètres ajustés
    print("Tentative stratégie 1: Paramètres ajustés")
    result, info = try_detection_strategy_1(gray, debug_path)
    debug_info["strategy_1"] = info
    if result is not None:
        debug_info["successful_strategy"] = 1
        return result, debug_info
    
    # Stratégie 2: Amélioration du contraste
    print("Tentative stratégie 2: Amélioration contraste")
    result, info = try_detection_strategy_2(gray, debug_path)
    debug_info["strategy_2"] = info
    if result is not None:
        debug_info["successful_strategy"] = 2
        return result, debug_info
    
    # Stratégie 3: Seuillage adaptatif
    print("Tentative stratégie 3: Seuillage adaptatif")
    result, info = try_detection_strategy_3(gray, debug_path)
    debug_info["strategy_3"] = info
    if result is not None:
        debug_info["successful_strategy"] = 3
        return result, debug_info
    
    debug_info["successful_strategy"] = None
    return None, debug_info

def try_detection_strategy_1(gray, debug_path=None):
    """Stratégie 1: Méthode actuelle avec paramètres ajustés"""
    blurred = cv2.GaussianBlur(gray, (5, 5), 0)
    
    if debug_path:
        cv2.imwrite(f"{debug_path}_s1_blurred.jpg", blurred)
    
    # Seuils Canny plus bas
    edges = cv2.Canny(blurred, 30, 100)
    
    if debug_path:
        cv2.imwrite(f"{debug_path}_s1_edges.jpg", edges)
    
    result, info = find_a4_in_edges(edges, tolerance=0.15, min_area=5000, strategy="1")
    return result, info

def try_detection_strategy_2(gray, debug_path=None):
    """Stratégie 2: Amélioration du contraste avec CLAHE"""
    clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8,8))
    enhanced = clahe.apply(gray)
    
    if debug_path:
        cv2.imwrite(f"{debug_path}_s2_enhanced.jpg", enhanced)
    
    blurred = cv2.GaussianBlur(enhanced, (5, 5), 0)
    edges = cv2.Canny(blurred, 40, 120)
    
    if debug_path:
        cv2.imwrite(f"{debug_path}_s2_edges.jpg", edges)
    
    result, info = find_a4_in_edges(edges, tolerance=0.12, min_area=4000, strategy="2")
    return result, info

def try_detection_strategy_3(gray, debug_path=None):
    """Stratégie 3: Seuillage adaptatif + morphologie"""
    # Seuillage adaptatif
    thresh = cv2.adaptiveThreshold(gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, 
                                  cv2.THRESH_BINARY, 11, 2)
    
    if debug_path:
        cv2.imwrite(f"{debug_path}_s3_thresh.jpg", thresh)
    
    # Opérations morphologiques
    kernel = np.ones((3,3), np.uint8)
    thresh = cv2.morphologyEx(thresh, cv2.MORPH_CLOSE, kernel)
    thresh = cv2.morphologyEx(thresh, cv2.MORPH_OPEN, kernel)
    
    if debug_path:
        cv2.imwrite(f"{debug_path}_s3_morph.jpg", thresh)
    
    # Détection des contours
    edges = cv2.Canny(thresh, 30, 80)
    
    # Dilatation pour connecter les contours brisés
    kernel = np.ones((2,2), np.uint8)
    edges = cv2.dilate(edges, kernel, iterations=1)
    
    if debug_path:
        cv2.imwrite(f"{debug_path}_s3_edges.jpg", edges)
    
    result, info = find_a4_in_edges(edges, tolerance=0.18, min_area=3000, strategy="3")
    return result, info

def find_a4_in_edges(edges, tolerance=0.1, min_area=10000, strategy="default"):
    """
    Chercher une feuille A4 dans une image de contours.
    """
    info = {
        "strategy": strategy,
        "tolerance": tolerance,
        "min_area": min_area,
        "contours_found": 0,
        "candidates_analyzed": 0,
        "rejection_reasons": []
    }
    
    # Trouver les contours
    contours, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    info["contours_found"] = len(contours)
    
    if len(contours) == 0:
        info["rejection_reasons"].append("Aucun contour trouvé")
        return None, info
    
    # Filtrer et trier les contours par aire
    contours = sorted(contours, key=cv2.contourArea, reverse=True)
    
    # Ratio A4: 210/297 ≈ 0.707
    target_ratio = 210.0 / 297.0
    
    for i, contour in enumerate(contours[:15]):  # Examiner plus de contours
        info["candidates_analyzed"] = i + 1
        
        area = cv2.contourArea(contour)
        if area < min_area:
            info["rejection_reasons"].append(f"Contour {i+1}: Aire trop petite ({area:.0f} < {min_area})")
            continue
        
        # Essayer différents niveaux d'approximation
        for epsilon_factor in [0.02, 0.03, 0.04, 0.05]:
            epsilon = epsilon_factor * cv2.arcLength(contour, True)
            approx = cv2.approxPolyDP(contour, epsilon, True)
            
            # Vérifier si c'est un quadrilatère (ou proche)
            if 4 <= len(approx) <= 6:
                # Si plus de 4 points, prendre les 4 coins les plus éloignés
                if len(approx) > 4:
                    # Simplifier en gardant les 4 points les plus éloignés
                    hull = cv2.convexHull(approx)
                    if len(hull) >= 4:
                        # Prendre 4 points équidistants sur l'enveloppe convexe
                        n_points = len(hull)
                        indices = [0, n_points//4, n_points//2, 3*n_points//4]
                        approx = hull[indices]
                
                if len(approx) == 4:
                    # Ordonner les coins
                    corners = approx.reshape(4, 2)
                    corners = order_corners(corners)
                    
                    # Calculer les dimensions
                    width = np.linalg.norm(corners[1] - corners[0])
                    height = np.linalg.norm(corners[3] - corners[0])
                    
                    # Vérifier le ratio d'aspect
                    ratio = min(width, height) / max(width, height)
                    
                    ratio_diff = abs(ratio - target_ratio)
                    if ratio_diff < tolerance:
                        # Calculer pixels_per_mm
                        if width < height:  # Portrait
                            pixels_per_mm_w = width / 210.0
                            pixels_per_mm_h = height / 297.0
                        else:  # Paysage
                            pixels_per_mm_w = width / 297.0
                            pixels_per_mm_h = height / 210.0
                        
                        pixels_per_mm = (pixels_per_mm_w + pixels_per_mm_h) / 2.0
                        
                        info["success"] = {
                            "contour_index": i + 1,
                            "epsilon_factor": epsilon_factor,
                            "area": area,
                            "width": width,
                            "height": height,
                            "ratio": ratio,
                            "ratio_diff": ratio_diff,
                            "pixels_per_mm": pixels_per_mm
                        }
                        
                        return corners, pixels_per_mm
                    else:
                        info["rejection_reasons"].append(
                            f"Contour {i+1} (ε={epsilon_factor}): Ratio incorrect ({ratio:.3f}, diff={ratio_diff:.3f} > {tolerance})"
                        )
                else:
                    info["rejection_reasons"].append(
                        f"Contour {i+1} (ε={epsilon_factor}): Pas exactement 4 points après simplification ({len(approx)})"
                    )
            else:
                info["rejection_reasons"].append(
                    f"Contour {i+1} (ε={epsilon_factor}): Nb points incorrect ({len(approx)})"
                )
    
    return None, info

def order_corners(corners: np.ndarray) -> np.ndarray:
    """
    Ordonner les coins dans l'ordre: haut-gauche, haut-droit, bas-droit, bas-gauche.
    """
    # Calculer le centre
    center = np.mean(corners, axis=0)
    
    # Calculer les angles par rapport au centre
    angles = np.arctan2(corners[:, 1] - center[1], corners[:, 0] - center[0])
    
    # Trier par angle
    sorted_indices = np.argsort(angles)
    sorted_corners = corners[sorted_indices]
    
    # Trouver le coin supérieur gauche (somme x+y minimale)
    top_left_idx = np.argmin(sorted_corners[:, 0] + sorted_corners[:, 1])
    
    # Réorganiser pour commencer par le coin supérieur gauche
    ordered = np.roll(sorted_corners, -top_left_idx, axis=0)
    
    return ordered

def suggest_measurements(image: np.ndarray, pixels_per_mm: float) -> List[MeasurementSuggestion]:
    """
    Suggérer des zones à mesurer dans l'image.
    """
    suggestions = []
    
    # Convertir en niveaux de gris
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    
    # Appliquer un seuillage adaptatif
    thresh = cv2.adaptiveThreshold(gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, 
                                  cv2.THRESH_BINARY_INV, 11, 2)
    
    # Opérations morphologiques pour nettoyer
    kernel = np.ones((3, 3), np.uint8)
    cleaned = cv2.morphologyEx(thresh, cv2.MORPH_CLOSE, kernel)
    cleaned = cv2.morphologyEx(cleaned, cv2.MORPH_OPEN, kernel)
    
    # Trouver les contours
    contours, _ = cv2.findContours(cleaned, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    
    # Filtrer et analyser les contours
    for contour in contours:
        area = cv2.contourArea(contour)
        if area < 1000:  # Ignorer les petits contours
            continue
        
        # Approximer le contour
        epsilon = 0.02 * cv2.arcLength(contour, True)
        approx = cv2.approxPolyDP(contour, epsilon, True)
        
        # Convertir en liste de points
        points = approx.reshape(-1, 2).tolist()
        
        # Déterminer le type de mesure
        if len(points) == 2:
            measure_type = "length"
        else:
            measure_type = "area"
        
        # Calculer la confiance basée sur la régularité du contour
        perimeter = cv2.arcLength(contour, True)
        compactness = 4 * np.pi * area / (perimeter * perimeter)
        confidence = min(compactness, 1.0)
        
        suggestions.append(MeasurementSuggestion(
            mask_poly=points,
            confidence=confidence,
            type=measure_type
        ))
    
    # Trier par confiance décroissante
    suggestions.sort(key=lambda x: x.confidence, reverse=True)
    
    # Limiter à 5 suggestions
    return suggestions[:5]

def annotate_image(image: np.ndarray, marker_corners: Optional[np.ndarray], 
                  suggestions: List[MeasurementSuggestion]) -> str:
    """
    Annoter l'image avec les détections et sauvegarder.
    """
    annotated = image.copy()
    
    # Dessiner le marqueur A4 si détecté
    if marker_corners is not None:
        cv2.drawContours(annotated, [marker_corners.astype(int)], -1, (0, 255, 0), 3)
        
        # Ajouter des labels aux coins
        for i, corner in enumerate(marker_corners):
            cv2.circle(annotated, tuple(corner.astype(int)), 8, (0, 255, 0), -1)
            cv2.putText(annotated, f"C{i+1}", tuple(corner.astype(int) + 10), 
                       cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)
    else:
        # Ajouter un message d'échec de détection
        cv2.putText(annotated, "Feuille A4 non detectee", (50, 50), 
                   cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)
    
    # Dessiner les suggestions
    for i, suggestion in enumerate(suggestions):
        points = np.array(suggestion.mask_poly, dtype=np.int32)
        color = (255, 0, 0) if suggestion.type == "area" else (0, 0, 255)
        
        if suggestion.type == "area":
            cv2.drawContours(annotated, [points], -1, color, 2)
        else:
            cv2.polylines(annotated, [points], False, color, 2)
        
        # Ajouter un label de confiance
        center = np.mean(points, axis=0).astype(int)
        cv2.putText(annotated, f"{suggestion.confidence:.2f}", tuple(center), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 2)
    
    # Sauvegarder l'image annotée
    filename = f"annotated_{uuid.uuid4().hex}.jpg"
    filepath = PROCESSED_DIR / filename
    cv2.imwrite(str(filepath), annotated)
    
    return f"/processed/{filename}"

@app.get("/")
async def root():
    return {
        "service": "Service IA de Mesure Menui - Version Améliorée",
        "version": "1.1.0",
        "endpoints": ["/analyze", "/analyze-debug", "/warp", "/health"]
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": datetime.utcnow().isoformat()}

@app.post("/analyze-debug", response_model=AnalyzeResponse)
async def analyze_debug(
    file: UploadFile = File(...),
    metadata: Optional[str] = Form(None)
):
    """
    Version de debug pour analyser en détail les échecs de détection.
    """
    try:
        # Sauvegarder le fichier uploadé
        file_id = uuid.uuid4().hex
        file_path = UPLOAD_DIR / f"{file_id}_{file.filename}"
        debug_path = DEBUG_DIR / f"debug_{file_id}"
        
        async with aiofiles.open(file_path, 'wb') as f:
            content = await file.read()
            await f.write(content)
        
        # Lire l'image avec OpenCV
        nparr = np.frombuffer(content, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if image is None:
            raise HTTPException(status_code=400, detail="Impossible de lire l'image")
        
        # Détecter le marqueur A4 avec debug
        detection_result = detect_a4_marker_robust(image, str(debug_path))
        
        if detection_result[0] is not None:
            marker_corners, pixels_per_mm = detection_result[0]
            debug_info = detection_result[1]
            success = True
            message = f"Feuille A4 détectée avec la stratégie {debug_info.get('successful_strategy', 'inconnue')}"
            
            # Suggérer des mesures
            suggestions = suggest_measurements(image, pixels_per_mm)
            
            # Créer des mesures préliminaires
            preliminary_measurements = [
                {
                    "id": f"prelim_{i}",
                    "type": suggestion.type,
                    "confidence": suggestion.confidence,
                    "points": suggestion.mask_poly,
                }
                for i, suggestion in enumerate(suggestions)
            ]
            
            marker = {
                "corners": marker_corners.tolist(),
                "type": "A4",
                "confidence": 1.0
            }
            
        else:
            marker_corners = None
            pixels_per_mm = None
            marker = None
            debug_info = detection_result[1]
            success = False
            message = "Échec de détection de la feuille A4"
            suggestions = []
            preliminary_measurements = []
        
        # Annoter l'image
        annotated_url = annotate_image(image, marker_corners, suggestions)
        
        return AnalyzeResponse(
            marker=marker,
            pixels_per_mm=pixels_per_mm,
            suggestions=suggestions,
            preliminary_measurements=preliminary_measurements,
            annotated_image_url=annotated_url,
            success=success,
            message=message,
            debug_info=debug_info
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Monter les répertoires statiques
app.mount("/processed", StaticFiles(directory=str(PROCESSED_DIR)), name="processed")
app.mount("/debug", StaticFiles(directory=str(DEBUG_DIR)), name="debug")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
