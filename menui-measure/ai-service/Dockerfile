# Dockerfile simple pour le service IA uniquement
FROM python:3.11-slim

# Métadonnées
LABEL maintainer="Menui Measure Team"
LABEL description="Service IA pour l'analyse et la mesure d'images"

# Variables d'environnement
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV APP_ENV=production

# Installation des dépendances système nécessaires pour OpenCV
RUN apt-get update && apt-get install -y \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    libgomp1 \
    libgthread-2.0-0 \
    libgtk-3-0 \
    libgl1-mesa-glx \
    libice6 \
    libfontconfig1 \
    libxss1 \
    libgstreamer1.0-0 \
    libgstreamer-plugins-base1.0-0 \
    ffmpeg \
    wget \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Création du répertoire de travail
WORKDIR /app

# Copie des fichiers de dépendances
COPY requirements.txt .

# Installation des dépendances Python
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

# Copie du code source
COPY . .

# Création des répertoires nécessaires
RUN mkdir -p /app/uploads /app/processed

# Exposition du port
EXPOSE 8000

# Commande de démarrage
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]