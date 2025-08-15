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

app = FastAPI(title="Service IA de Mesure Menui", version="1.0.0")

# Configuration
# Déterminer le répertoire de base selon l'environnement
if os.name == 'nt':  # Windows
    BASE_DIR = Path(__file__).parent
    UPLOAD_DIR = BASE_DIR / "uploads"
    PROCESSED_DIR = BASE_DIR / "processed"
else:  # Docker/Linux
    UPLOAD_DIR = Path("/app/uploads")
    PROCESSED_DIR = Path("/app/processed")

UPLOAD_DIR.mkdir(exist_ok=True)
PROCESSED_DIR.mkdir(exist_ok=True)

# Monter les répertoires statiques
app.mount("/uploads", StaticFiles(directory=str(UPLOAD_DIR)), name="uploads")
app.mount("/processed", StaticFiles(directory=str(PROCESSED_DIR)), name="processed")

class MarkerDetection(BaseModel):
    corners: List[List[float]]
    confidence: float
    pixels_per_mm: float

class MeasurementSuggestion(BaseModel):
    mask_poly: List[List[float]]
    confidence: float
    type: str  # "length" ou "area"

class AnalyzeResponse(BaseModel):
    marker: Optional[MarkerDetection]
    pixels_per_mm: Optional[float]
    suggestions: List[MeasurementSuggestion]
    preliminary_measurements: List[Dict[str, Any]]
    annotated_image_url: str
    success: bool
    message: str

class WarpRequest(BaseModel):
    image_path: str
    marker_corners: List[List[float]]

def detect_a4_marker(image: np.ndarray) -> Optional[Tuple[np.ndarray, float]]:
    """
    Détecter une feuille A4 dans l'image.
    Retourne les coins et le facteur pixels_per_mm.
    """
    # Convertir en niveaux de gris
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    
    # Appliquer un flou gaussien pour réduire le bruit
    blurred = cv2.GaussianBlur(gray, (5, 5), 0)
    
    # Détection des contours avec Canny
    edges = cv2.Canny(blurred, 50, 150)
    
    # Trouver les contours
    contours, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    
    # Filtrer et trier les contours par aire
    contours = sorted(contours, key=cv2.contourArea, reverse=True)
    
    # Ratio A4: 210/297 ≈ 0.707
    target_ratio = 210.0 / 297.0
    tolerance = 0.1  # 10% de tolérance
    
    for contour in contours[:10]:  # Examiner les 10 plus grands contours
        # Approximer le contour à un polygone
        epsilon = 0.02 * cv2.arcLength(contour, True)
        approx = cv2.approxPolyDP(contour, epsilon, True)
        
        # Vérifier si c'est un quadrilatère
        if len(approx) == 4:
            # Calculer l'aire
            area = cv2.contourArea(approx)
            if area < 10000:  # Ignorer les petits contours
                continue
            
            # Ordonner les coins
            corners = approx.reshape(4, 2)
            corners = order_corners(corners)
            
            # Calculer les dimensions
            width = np.linalg.norm(corners[1] - corners[0])
            height = np.linalg.norm(corners[3] - corners[0])
            
            # Vérifier le ratio d'aspect
            ratio = min(width, height) / max(width, height)
            
            if abs(ratio - target_ratio) < tolerance:
                # Calculer pixels_per_mm
                if width < height:  # Portrait
                    pixels_per_mm_w = width / 210.0
                    pixels_per_mm_h = height / 297.0
                else:  # Paysage
                    pixels_per_mm_w = width / 297.0
                    pixels_per_mm_h = height / 210.0
                
                pixels_per_mm = (pixels_per_mm_w + pixels_per_mm_h) / 2.0
                
                return corners, pixels_per_mm
    
    return None

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

def compute_homography(src_corners: np.ndarray, dst_size: Tuple[int, int]) -> np.ndarray:
    """
    Calculer la matrice d'homographie pour transformer l'image en vue de dessus.
    """
    dst_corners = np.array([
        [0, 0],
        [dst_size[0] - 1, 0],
        [dst_size[0] - 1, dst_size[1] - 1],
        [0, dst_size[1] - 1]
    ], dtype=np.float32)
    
    H, _ = cv2.findHomography(src_corners, dst_corners)
    return H

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
    """Point d'entrée de l'API."""
    return {
        "service": "Service IA de Mesure Menui",
        "version": "1.0.0",
        "endpoints": ["/analyze", "/warp", "/health"]
    }

@app.get("/health")
async def health_check():
    """Vérification de l'état du service."""
    return {"status": "healthy", "timestamp": datetime.utcnow().isoformat()}

@app.post("/analyze", response_model=AnalyzeResponse)
async def analyze(
    file: UploadFile = File(...),
    metadata: Optional[str] = Form(None)
):
    """
    Analyser une image pour détecter le marqueur A4 et suggérer des mesures.
    """
    try:
        # Sauvegarder le fichier uploadé
        file_id = uuid.uuid4().hex
        file_path = UPLOAD_DIR / f"{file_id}_{file.filename}"
        
        async with aiofiles.open(file_path, 'wb') as f:
            content = await file.read()
            await f.write(content)
        
        # Lire l'image avec OpenCV
        nparr = np.frombuffer(content, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if image is None:
            raise HTTPException(status_code=400, detail="Image invalide")
        
        # Détecter le marqueur A4
        detection_result = detect_a4_marker(image)
        
        if detection_result is not None:
            marker_corners, pixels_per_mm = detection_result
            marker = MarkerDetection(
                corners=marker_corners.tolist(),
                confidence=0.95,
                pixels_per_mm=pixels_per_mm
            )
            
            # Suggérer des mesures
            suggestions = suggest_measurements(image, pixels_per_mm)
            
            # Calculer des mesures préliminaires
            preliminary_measurements = []
            for i, suggestion in enumerate(suggestions):
                if suggestion.type == "area":
                    area_px = cv2.contourArea(np.array(suggestion.mask_poly, dtype=np.int32))
                    area_mm2 = area_px / (pixels_per_mm ** 2)
                    area_m2 = area_mm2 / 1_000_000
                    
                    preliminary_measurements.append({
                        "id": i,
                        "type": "area",
                        "value_mm2": area_mm2,
                        "value_m2": area_m2,
                        "confidence": suggestion.confidence
                    })
                else:
                    points = np.array(suggestion.mask_poly)
                    if len(points) >= 2:
                        length_px = np.linalg.norm(points[1] - points[0])
                        length_mm = length_px / pixels_per_mm
                        
                        preliminary_measurements.append({
                            "id": i,
                            "type": "length",
                            "value_mm": length_mm,
                            "confidence": suggestion.confidence
                        })
            
            success = True
            message = "Marqueur A4 détecté avec succès"
        else:
            marker = None
            pixels_per_mm = None
            suggestions = []
            preliminary_measurements = []
            success = False
            message = "Aucun marqueur A4 détecté. Veuillez vous assurer que la feuille A4 est visible et bien éclairée."
        
        # Annoter l'image
        annotated_url = annotate_image(
            image, 
            marker_corners if detection_result else None,
            suggestions
        )
        
        return AnalyzeResponse(
            marker=marker,
            pixels_per_mm=pixels_per_mm,
            suggestions=suggestions,
            preliminary_measurements=preliminary_measurements,
            annotated_image_url=annotated_url,
            success=success,
            message=message
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/warp")
async def warp_perspective(request: WarpRequest):
    """
    Appliquer une transformation de perspective pour obtenir une vue de dessus.
    """
    try:
        # Charger l'image
        image_path = UPLOAD_DIR / Path(request.image_path).name
        if not image_path.exists():
            raise HTTPException(status_code=404, detail="Image non trouvée")
        
        image = cv2.imread(str(image_path))
        if image is None:
            raise HTTPException(status_code=400, detail="Impossible de lire l'image")
        
        # Convertir les coins en numpy array
        src_corners = np.array(request.marker_corners, dtype=np.float32)
        
        # Calculer la taille de destination (A4 en pixels à 300 DPI)
        # 210mm x 297mm à 300 DPI ≈ 2480 x 3508 pixels
        dst_width = 2480
        dst_height = 3508
        
        # Calculer l'homographie
        H = compute_homography(src_corners, (dst_width, dst_height))
        
        # Appliquer la transformation
        warped = cv2.warpPerspective(image, H, (dst_width, dst_height))
        
        # Sauvegarder l'image transformée
        filename = f"warped_{uuid.uuid4().hex}.jpg"
        filepath = PROCESSED_DIR / filename
        cv2.imwrite(str(filepath), warped)
        
        return {
            "warped_image_url": f"/processed/{filename}",
            "homography_matrix": H.tolist(),
            "output_size": [dst_width, dst_height]
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)