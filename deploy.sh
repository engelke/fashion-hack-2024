#!/bin/bash

# Exit on error
set -e

echo "🚀 Starting deployment process..."

# Get the project ID
GOOGLE_CLOUD_PROJECT=$(gcloud config get-value project)
echo "Using Google Cloud Project: $GOOGLE_CLOUD_PROJECT"

# Get the project number
PROJECT_NUMBER=$(gcloud projects describe $GOOGLE_CLOUD_PROJECT --format="value(projectNumber)")
echo "Project Number: $PROJECT_NUMBER"

# Set up service account permissions
echo "🔐 Setting up IAM permissions..."
FUNCTION_SA="$PROJECT_NUMBER-compute@developer.gserviceaccount.com"

# Grant necessary roles to the service account
echo "Granting roles to $FUNCTION_SA..."
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
  --member="serviceAccount:$FUNCTION_SA" \
  --role="roles/storage.objectViewer"

gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
  --member="serviceAccount:$FUNCTION_SA" \
  --role="roles/iam.serviceAccountTokenCreator"

# Deploy Cloud Functions
echo "🔧 Deploying Cloud Functions..."
cd backend/functions

# Install dependencies
echo "📦 Installing Cloud Function dependencies..."
npm install @google-cloud/vertexai @google-cloud/storage cors

#Deploy getSignedUrl function
echo "🔑 Deploying getSignedUrl function..."
gcloud functions deploy getSignedUrl \
  --runtime nodejs20 \
  --trigger-http \
  --allow-unauthenticated \
  --region us-central1 \
  --service-account=$FUNCTION_SA \
  --set-env-vars GOOGLE_CLOUD_PROJECT=$GOOGLE_CLOUD_PROJECT

# Deploy fashionAI function
echo "🤖 Deploying fashion AI function..."
gcloud functions deploy getOutfitSuggestions \
  --runtime nodejs20 \
  --trigger-http \
  --allow-unauthenticated \
  --region us-central1 \
  --service-account=$FUNCTION_SA \
  --set-env-vars GOOGLE_CLOUD_PROJECT=$GOOGLE_CLOUD_PROJECT

# Get the Cloud Function URLs
SIGNED_URL_FUNCTION=$(gcloud functions describe getSignedUrl --region us-central1 --format='value(httpsTrigger.url)')
FASHION_AI_FUNCTION=$(gcloud functions describe getOutfitSuggestions --region us-central1 --format='value(httpsTrigger.url)')
cd ../..

# Update the service configurations
echo "📝 Updating service configurations..."
sed -i '' "s|YOUR_CLOUD_FUNCTION_URL|$SIGNED_URL_FUNCTION|g" frontend/lib/services/api_service.dart
sed -i '' "s|YOUR_GCS_BUCKET_NAME|fashion-hacks-2024-uploads|g" frontend/lib/services/api_service.dart
sed -i '' "s|YOUR_FASHION_AI_FUNCTION_URL|$FASHION_AI_FUNCTION|g" frontend/lib/services/vision_service.dart

# Build the Flutter web app with Firebase configuration
echo "📦 Building Flutter web app..."
cd frontend
/Users/miav/bin/flutter/bin/flutter build web --release \
  --dart-define=FIREBASE_API_KEY="AIzaSyBxjOzHuJxZGxkJe_XwH_jFSdYGvL1uNYE" \
  --dart-define=FIREBASE_APP_ID="1:348449317363:web:c0c0c0c0c0c0c0c0c0c0c0" \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID="348449317363" \
  --dart-define=FIREBASE_PROJECT_ID="fashion-hack-2024" \
  --dart-define=FIREBASE_AUTH_DOMAIN="fashion-hack-2024.firebaseapp.com" \
  --dart-define=FIREBASE_STORAGE_BUCKET="fashion-hack-2024.appspot.com"
cd ..

# Create a Dockerfile for the web app
echo "🐳 Creating Dockerfile..."
cat > frontend/Dockerfile << 'EOF'
FROM nginx:alpine

# Copy the built web app to nginx directory
COPY build/web /usr/share/nginx/html

# Create icons directory if it doesn't exist
RUN mkdir -p /usr/share/nginx/html/icons

# Copy icons
COPY build/web/icons/apple-touch-icon.png /usr/share/nginx/html/icons/
COPY build/web/icons/favicon-96x96.png /usr/share/nginx/html/icons/
COPY build/web/icons/favicon.ico /usr/share/nginx/html/icons/
COPY build/web/icons/favicon.svg /usr/share/nginx/html/icons/
COPY build/web/icons/web-app-manifest-192x192.png /usr/share/nginx/html/icons/
COPY build/web/icons/web-app-manifest-512x512.png /usr/share/nginx/html/icons/

# Expose port 8080 (Cloud Run requirement)
EXPOSE 8080

# Update nginx config to listen on port 8080
RUN sed -i 's/80/8080/g' /etc/nginx/conf.d/default.conf
EOF

# Build and deploy to Cloud Run
echo "🏗️ Building and deploying to Cloud Run..."
cd frontend

# Build the container
echo "🔨 Building container..."
gcloud builds submit --tag gcr.io/$GOOGLE_CLOUD_PROJECT/fashion-hack

# Deploy to Cloud Run
echo "🚀 Deploying to Cloud Run..."
gcloud run deploy fashion-hack \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/fashion-hack \
  --platform managed \
  --allow-unauthenticated \
  --region us-central1

echo "✅ Deployment complete!" 