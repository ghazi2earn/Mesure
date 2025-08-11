{
  "project": {
    "name": "menui-measure",
    "description": "Application web pour mesurer surfaces/longueurs à partir de photos (référence: feuille A4), stack Laravel12 + React + Tailwind + shadcn + Inertia + microservice FastAPI(OpenCV). Hébergement OVH.",
    "author": "Ghazi Tounsi",
    "guest_reference": "A4 (210x297 mm)"
  },
  "tech_stack": {
    "backend": "Laravel 12 + Inertia.js",
    "frontend": "React 18 + Tailwind CSS + shadcn/ui",
    "ai_service": "Python 3.11 + FastAPI + OpenCV + NumPy",
    "db": "MySQL 8",
    "queue": "Redis + Laravel Queue",
    "storage": "S3-compatible (OVH Object Storage) or local",
    "deployment": "Docker Compose + Nginx + OVH VPS + Certbot"
  },
  "deliverables": [
    "Monorepo with laravel-app/, frontend inside laravel resources (Inertia), ai-service/",
    "Docker Compose dev & prod",
    "Migrations: users, tasks, photos, subtasks, measurements, notifications_log",
    "FastAPI microservice with endpoints /analyze and /warp",
    "React components: TaskList, TaskDetail, GuestUpload, ImageAnnotator (Konva)",
    "CI-ready README and OVH deployment guide"
  ],
  "database_schema": {
    "users": ["id pk", "name string", "email string unique", "password", "role enum(admin,client)", "timestamps"],
    "tasks": ["id pk", "title", "description text nullable", "status enum(nouveau,en_attente,en_execution,cloture)", "guest_token string nullable", "guest_expires datetime nullable", "user_id fk users", "assigned_to nullable", "timestamps"],
    "photos": ["id pk", "task_id fk tasks", "path string", "exif json nullable", "width_px int", "height_px int", "processed boolean default false", "metadata json", "timestamps"],
    "measurements": ["id pk", "task_id fk", "photo_id fk nullable", "subtask_id fk nullable", "type enum(length,area)", "value_mm float nullable", "value_mm2 float nullable", "value_m2 float nullable", "points json", "mask_path nullable", "annotated_path nullable", "confidence float", "processor_version string", "timestamps"],
    "subtasks": ["id pk", "task_id fk", "title", "type enum(longueur,surface)", "value float nullable", "unit enum(m,m2)", "status", "timestamps"],
    "notifications_log": ["id pk", "task_id fk nullable", "type string", "payload json", "sent_at datetime", "status enum(sent,error)", "timestamps"]
  },
  "api_contracts": {
    "laravel_endpoints": [
      "POST /tasks -> create task (admin)",
      "POST /tasks/{id}/guest-link -> generate guest token, set status=en_attente",
      "GET /guest/{token} -> public upload page (Inertia)",
      "POST /guest/{token}/photos -> upload photos (store, queue ProcessUploadedPhotoJob)",
      "POST /tasks/{id}/photos/{photo}/process -> force reanalysis",
      "POST /tasks/{id}/photos/{photo}/measure -> accept polygon/points and compute final measure",
      "GET /measurements/{id} -> get measurement JSON including annotated image urls"
    ],
    "ai_service_endpoints": {
      "POST /analyze": {
        "input": "multipart image file, metadata JSON {expect_marker:'A4', points(optional)}",
        "output": "{ marker:{corners:[[x,y]...]}, pixels_per_mm:float, suggestions:[{mask_poly,confidence}], preliminary_measurements:[...], annotated_image_url }"
      },
      "POST /warp": {"input":"image + marker_corners", "output":"warped_image_url, homography_matrix"}
    }
  },
  "ai_pipeline_spec": [
    "1) Pré-traitement: normalize orientation (EXIF), resize keeping ratio",
    "2) Detection A4: find contours, approxPolyDP, filter by aspect ratio ~210/297 ± tol",
    "3) Compute pixels_per_mm: avg(width_px/210, height_px/297) or via homography",
    "4) If marker found -> compute homography -> warpPerspective to top-down",
    "5) Segmentation suggestion: use SAM or OpenCV contour heuristics to propose masks",
    "6) If admin selected 2 points -> distance = euclidean(px) / pixels_per_mm -> mm",
    "7) If polygon -> area_px -> area_mm2 = area_px / (pixels_per_mm^2) -> area_m2",
    "8) Return JSON with confidence and annotated image; save mask & annotated image"
  ],
  "ui_flow": {
    "admin": [
      "Dashboard: list tasks filtered by status",
      "Task detail: photos, measurements, create subtasks, reprocess",
      "Image viewer: shows detected A4 overlay, suggestions, polygon/2-point tool, save measurement",
      "Copy link button: generate guest token, copy URL to clipboard and set task.status=en_attente"
    ],
    "guest": [
      "Open public link, read short guide (how to place A4), upload 1..N photos, submit",
      "After submit: simple confirmation and optional phone/email field (optional)",
      "System notifies admin"
    ]
  },
  "ux_rules_and_photo_guidelines": [
    "Obligatory: A4 must be visible on the same plane as measured surface",
    "Angle ideally < 15°, if >15% allow homography but warn User about precision drop",
    "Good lighting, avoid heavy shadows/reflections",
    "If area is larger than frame -> multiple overlapping photos (stitching option)"
  ],
  "sprints_compact": [
    {
      "sprint": "Sprint 0 - Init",
      "duration_days": 3,
      "tasks": ["Monorepo skeleton", "Docker compose basic", "README", "env examples"]
    },
    {
      "sprint": "Sprint 1 - Core CRUD & Guest Flow",
      "duration_days": 10,
      "tasks": ["Migrations & models", "Task CRUD admin pages", "Guest link generation", "Public upload page", "ProcessUploadedPhotoJob stub"]
    },
    {
      "sprint": "Sprint 2 - AI core",
      "duration_days": 12,
      "tasks": ["FastAPI service A4 detection", "POST /analyze implementation", "Laravel job integration", "store preliminary results & annotated image"]
    },
    {
      "sprint": "Sprint 3 - Semi-auto UI & measurement",
      "duration_days": 14,
      "tasks": ["React image annotator (Konva)", "Send polygon/points to backend", "Final measurement compute using pixels_per_mm", "annotated image + PDF generation"]
    },
    {
      "sprint": "Sprint 4 - Features & infra",
      "duration_days": 10,
      "tasks": ["Subtasks management", "Stitching (opt)", "WhatsApp integration (Twilio) + Push", "OVH deployment scripts"]
    },
    {
      "sprint": "Sprint 5 - Hardening & tests",
      "duration_days": 7,
      "tasks": ["Unit & integration tests (Laravel & Python)", "Load test basic", "Logging & monitoring", "Deploy to staging OVH"]
    }
  ],
  "file_templates": [
    {
      "path": "docker-compose.yml",
      "content": "version: '3.8'\\nservices:\\n  db: image: mysql:8 environment: MYSQL_ROOT_PASSWORD=root MYSQL_DATABASE=menui ...\\n  redis: image: redis:6\\n  laravel: build: ./laravel-app ... ports: ['8000:80'] depends_on: [db,redis]\\n  node: ...\\n  ai-service: build: ./ai-service ports: ['8001:8000'] command: uvicorn main:app --host 0.0.0.0 --port 8000"
    },
    {
      "path": "laravel-app/.env.example",
      "content": "APP_NAME=menui\\nAPP_ENV=local\\nDB_CONNECTION=mysql\\nDB_HOST=db\\nDB_PORT=3306\\nDB_DATABASE=menui\\nDB_USERNAME=root\\nDB_PASSWORD=root\\nREDIS_HOST=redis\\nAI_SERVICE_URL=http://ai-service:8000"
    },
    {
      "path": "laravel-app/database/migrations/2025_01_01_000000_create_tasks_table.php",
      "content": "// migration skeleton: id, title, description, status enum, guest_token, guest_expires, user_id, assigned_to, timestamps"
    },
    {
      "path": "laravel-app/app/Jobs/ProcessUploadedPhotoJob.php",
      "content": "// Job: reads photo path, calls AI_SERVICE_URL/analyze via HTTP multipart, stores returned measurements, mask and annotated image paths, sets photo.processed=true"
    },
    {
      "path": "laravel-app/routes/web.php",
      "content": "// routes: resource tasks, POST tasks/{id}/guest-link, GET guest/{token}, POST guest/{token}/photos, POST tasks/{id}/photos/{photo}/measure"
    },
    {
      "path": "laravel-app/app/Http/Controllers/GuestUploadController.php",
      "content": "// handle public upload: validate token, store files, dispatch ProcessUploadedPhotoJob, respond success"
    },
    {
      "path": "laravel-app/resources/js/Pages/GuestUpload.jsx",
      "content": "// React page: instruction, file input, preview thumbnails, upload to /guest/{token}/photos"
    },
    {
      "path": "laravel-app/resources/js/Components/ImageAnnotator.jsx",
      "content": "// React Konva based component: supports draw polygon, draw 2 points, undo, send points to backend"
    },
    {
      "path": "ai-service/main.py",
      "content": "from fastapi import FastAPI, File, UploadFile, Form\\nimport cv2, numpy as np\\napp = FastAPI()\\n@app.post('/analyze')\\nasync def analyze(file: UploadFile = File(...), metadata: str = Form(None)):\\n  contents = await file.read()\\n  nparr = np.frombuffer(contents, np.uint8)\\n  img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)\\n  # 1 - detect A4: convert to gray, blur, canny, findContours, approxPolyDP, filter quads by aspect ratio\\n  # 2 - compute pixels_per_mm and homography if found\\n  # 3 - warp perspective, detect contours for suggested masks (or call SAM if installed)\\n  # 4 - produce annotated image, save locally and return JSON with marker corners, pixels_per_mm, suggestions, annotated_url\\n  return {\"marker\": null, \"pixels_per_mm\": null, \"suggestions\": [], \"annotated_image_url\": null}"
    },
    {
      "path": "README.md",
      "content": "Project menui-measure - how to run: docker-compose up --build, Laravel: composer install, npm install && npm run dev, AI service: python -m pip install -r ai-service/requirements.txt, uvicorn. Deployment: see ./deploy/ovh.md"
    },
    {
      "path": "deploy/ovh.md",
      "content": "Steps to deploy on OVH VPS: 1) install Docker & docker-compose, 2) clone repo, 3) set env vars, 4) docker-compose -f docker-compose.prod.yml up -d, 5) configure Nginx reverse proxy, 6) certbot for SSL, 7) configure OVH Object Storage S3 keys in .env"
    }
  ],
  "quality_and_metrics": {
    "initial_target": "MAE < 10 mm on controlled dataset",
    "goal_after_improvements": "MAE < 5 mm given good photos (A4 on same plane and angle <15°)",
    "tests": ["unit tests Laravel models/controllers", "pytest for ai-service detection functions", "integration: upload -> process -> measurement stored"],
    "logging": "store reasons for detection failure (no A4 found, low confidence) in notifications_log"
  },
  "security": {
    "guest_token": "uuid + HMAC signature, short expiry configurable (default 7 days)",
    "uploads": "max size 10MB, only jpg/png, virus scan optional",
    "rate_limit": "per IP upload throttle for guest endpoints"
  },
  "final_instructions_for_cursor": [
    "Generate full repo following this JSON strictly.",
    "Create runnable docker-compose dev environment.",
    "Implement minimal but functional AI analyze endpoint (A4 detection + pixels_per_mm + annotated image).",
    "Implement React ImageAnnotator with Konva supporting polygon & 2-points saving.",
    "Make all strings and key comments in French.",
    "Add README run & deploy steps; include sample images in /dataset/sample for testing."
  ]
}
