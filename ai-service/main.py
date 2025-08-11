from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
import cv2
import numpy as np
import json
import uuid
import os
from pathlib import Path
from typing import Optional, List, Dict, Any
import logging

# Configuration du logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Menui Measure AI Service", version="1.0.0")

# Configuration CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Dossiers de stockage
STORAGE_DIR = Path("/app/storage")
ANNOTATED_DIR = STORAGE_DIR / "annotated"
MASKS_DIR = STORAGE_DIR / "masks"

# Créer les dossiers s'ils n'existent pas
for directory in [STORAGE_DIR, ANNOTATED_DIR, MASKS_DIR]:
    directory.mkdir(parents=True, exist_ok=True)

def detect_a4_marker(image: np.ndarray) -> Optional[Dict[str, Any]]:
    """
    Détecte le marqueur A4 dans l'image
    Retourne les coins du marqueur et les pixels par mm
    """
    try:
        # Conversion en niveaux de gris
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        
        # Flou gaussien pour réduire le bruit
        blurred = cv2.GaussianBlur(gray, (5, 5), 0)
        
        # Détection des contours avec Canny
        edges = cv2.Canny(blurred, 50, 150)
        
        # Trouver les contours
        contours, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        
        # Ratio A4 (210/297)
        a4_ratio = 210.0 / 297.0
        tolerance = 0.15
        
        for contour in contours:
            # Approximation polygonale
            epsilon = 0.02 * cv2.arcLength(contour, True)
            approx = cv2.approxPolyDP(contour, epsilon, True)
            
            # Vérifier si c'est un quadrilatère
            if len(approx) == 4:
                # Calculer les dimensions
                rect = cv2.boundingRect(approx)
                width, height = rect[2], rect[3]
                
                # Vérifier le ratio
                current_ratio = min(width, height) / max(width, height)
                if abs(current_ratio - a4_ratio) < tolerance:
                    # Calculer les pixels par mm
                    if width > height:
                        pixels_per_mm = width / 297.0  # Paysage
                    else:
                        pixels_per_mm = height / 297.0  # Portrait
                    
                    # Extraire les coins
                    corners = approx.reshape(-1, 2).tolist()
                    
                    return {
                        "corners": corners,
                        "pixels_per_mm": pixels_per_mm,
                        "confidence": 0.8  # Confiance basique
                    }
        
        return None
    except Exception as e:
        logger.error(f"Erreur lors de la détection A4: {e}")
        return None

def suggest_measurements(image: np.ndarray, pixels_per_mm: float) -> List[Dict[str, Any]]:
    """
    Suggère des zones à mesurer en utilisant la détection de contours
    """
    try:
        # Conversion en niveaux de gris
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        
        # Seuillage adaptatif
        thresh = cv2.adaptiveThreshold(gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY_INV, 11, 2)
        
        # Trouver les contours
        contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        
        suggestions = []
        for i, contour in enumerate(contours[:5]):  # Limiter à 5 suggestions
            area = cv2.contourArea(contour)
            if area > 1000:  # Filtrer les petits contours
                # Simplifier le contour
                epsilon = 0.02 * cv2.arcLength(contour, True)
                approx = cv2.approxPolyDP(contour, epsilon, True)
                
                mask_polygon = approx.reshape(-1, 2).tolist()
                
                suggestions.append({
                    "id": i,
                    "mask_poly": mask_polygon,
                    "confidence": min(0.7, area / 10000),  # Confiance basée sur la taille
                    "area_mm2": area / (pixels_per_mm ** 2)
                })
        
        return suggestions
    except Exception as e:
        logger.error(f"Erreur lors de la suggestion de mesures: {e}")
        return []

def create_annotated_image(image: np.ndarray, marker_data: Optional[Dict], suggestions: List[Dict]) -> str:
    """
    Crée une image annotée avec le marqueur A4 et les suggestions
    """
    try:
        annotated = image.copy()
        
        # Dessiner le marqueur A4 s'il est détecté
        if marker_data and marker_data.get("corners"):
            corners = np.array(marker_data["corners"], dtype=np.int32)
            cv2.polylines(annotated, [corners], True, (0, 255, 0), 3)
            cv2.putText(annotated, "A4 détecté", tuple(corners[0]), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
        
        # Dessiner les suggestions
        for suggestion in suggestions:
            if suggestion.get("mask_poly"):
                poly = np.array(suggestion["mask_poly"], dtype=np.int32)
                cv2.polylines(annotated, [poly], True, (255, 0, 0), 2)
                
                # Ajouter un label avec la surface estimée
                if suggestion.get("area_mm2"):
                    area_m2 = suggestion["area_mm2"] / 1000000
                    label = f"{area_m2:.3f} m²"
                    cv2.putText(annotated, label, tuple(poly[0]), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 0, 0), 1)
        
        # Sauvegarder l'image annotée
        filename = f"annotated_{uuid.uuid4().hex}.jpg"
        filepath = ANNOTATED_DIR / filename
        cv2.imwrite(str(filepath), annotated)
        
        return f"/storage/annotated/{filename}"
    except Exception as e:
        logger.error(f"Erreur lors de la création de l'image annotée: {e}")
        return ""

@app.post("/analyze")
async def analyze_image(
    file: UploadFile = File(...),
    metadata: Optional[str] = Form(None)
):
    """
    Analyse une image pour détecter le marqueur A4 et suggérer des mesures
    """
    try:
        # Lire l'image
        contents = await file.read()
        nparr = np.frombuffer(contents, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if image is None:
            raise HTTPException(status_code=400, detail="Image invalide")
        
        # Parser les métadonnées si fournies
        meta = {}
        if metadata:
            try:
                meta = json.loads(metadata)
            except json.JSONDecodeError:
                logger.warning("Métadonnées JSON invalides")
        
        # Détecter le marqueur A4
        marker_data = detect_a4_marker(image)
        
        suggestions = []
        preliminary_measurements = []
        
        if marker_data:
            # Suggérer des mesures
            suggestions = suggest_measurements(image, marker_data["pixels_per_mm"])
            
            # Créer des mesures préliminaires
            preliminary_measurements = [{
                "type": "area" if len(s.get("mask_poly", [])) > 2 else "length",
                "value_mm2": s.get("area_mm2"),
                "confidence": s.get("confidence", 0.5)
            } for s in suggestions]
        
        # Créer l'image annotée
        annotated_image_url = create_annotated_image(image, marker_data, suggestions)
        
        return {
            "marker": marker_data,
            "pixels_per_mm": marker_data.get("pixels_per_mm") if marker_data else None,
            "suggestions": suggestions,
            "preliminary_measurements": preliminary_measurements,
            "annotated_image_url": annotated_image_url
        }
        
    except Exception as e:
        logger.error(f"Erreur lors de l'analyse: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur d'analyse: {str(e)}")

@app.post("/warp")
async def warp_image(
    file: UploadFile = File(...),
    marker_corners: str = Form(...)
):
    """
    Applique une correction de perspective à l'image basée sur les coins du marqueur A4
    """
    try:
        # Lire l'image
        contents = await file.read()
        nparr = np.frombuffer(contents, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if image is None:
            raise HTTPException(status_code=400, detail="Image invalide")
        
        # Parser les coins du marqueur
        corners = json.loads(marker_corners)
        src_points = np.array(corners, dtype=np.float32)
        
        # Points de destination pour un A4 standard (ratio 210:297)
        width, height = 2100, 2970  # 10 pixels par mm
        dst_points = np.array([
            [0, 0],
            [width, 0],
            [width, height],
            [0, height]
        ], dtype=np.float32)
        
        # Calculer la matrice d'homographie
        homography_matrix = cv2.getPerspectiveTransform(src_points, dst_points)
        
        # Appliquer la correction de perspective
        warped = cv2.warpPerspective(image, homography_matrix, (width, height))
        
        # Sauvegarder l'image corrigée
        filename = f"warped_{uuid.uuid4().hex}.jpg"
        filepath = STORAGE_DIR / filename
        cv2.imwrite(str(filepath), warped)
        
        return {
            "warped_image_url": f"/storage/{filename}",
            "homography_matrix": homography_matrix.tolist()
        }
        
    except Exception as e:
        logger.error(f"Erreur lors de la correction de perspective: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur de correction: {str(e)}")

@app.get("/storage/{path:path}")
async def serve_file(path: str):
    """
    Sert les fichiers stockés
    """
    file_path = STORAGE_DIR / path
    if file_path.exists() and file_path.is_file():
        return FileResponse(file_path)
    raise HTTPException(status_code=404, detail="Fichier non trouvé")

@app.get("/")
async def root():
    return {"message": "Service AI Menui Measure", "version": "1.0.0"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)