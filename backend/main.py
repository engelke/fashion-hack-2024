from flask import Flask, request, render_template, jsonify
from google.cloud import storage, firestore
import vertexai
from vertexai.generative_models import GenerativeModel
import os
import uuid
import base64
import json

app = Flask(__name__)

# Configure Cloud Storage client
storage_client = storage.Client()
bucket_name = os.environ.get("CLOUD_STORAGE_BUCKET") # Get bucket name from environment variable
if not bucket_name:
    raise ValueError("CLOUD_STORAGE_BUCKET environment variable not set.")
bucket = storage_client.bucket(bucket_name)

# Initialize Firestore and Vertex AI
db = firestore.Client()
vertexai.init(project="fashion-hack-2024", location="us-west1")  # Initialize Vertex AI
model = GenerativeModel("gemini-1.5-flash")  # Load the Gemini model


@app.route("/", methods=["GET", "POST"])
def index():
    if request.method == "POST":
        uploaded_file = request.files.get("file")
        if uploaded_file:
            # Generate a unique filename to avoid collisions
            filename = str(uuid.uuid4()) + "." + uploaded_file.filename.split(".")[-1]

            # Create a blob in the bucket and upload the file data
            blob = bucket.blob(filename)
            blob.upload_from_file(uploaded_file)

            # Return a success message with the public URL of the uploaded image
            public_url = blob.public_url
            return jsonify({"message": "File uploaded successfully!", "url": public_url})
        else:
            return jsonify({"error": "No file selected."}), 400

    return render_template("index.html")

@app.route("/process/<filename>")
def add_metadata_to_firestore(filename):
    """
    Analyzes an image using Gemini and adds the extracted metadata to Firestore.
    """
    try:
        # Fetch the image from the public URL
        # (You might need to adjust this based on how your images are stored)
        storage_client = storage.Client()
        blob = storage_client.bucket(bucket_name).blob(filename) 
        image_bytes = blob.download_as_bytes()

        image = vertexai.generative_models.Image.from_bytes(image_bytes)

        # Make the prediction request to Gemini
        response = model.generate_content([image, 
                                          "Analyze this image of clothing and provide the following information as a JSON object: clothing_type, color, style, material, and occasion."]) 

        # Extract the metadata from the response (assuming JSON output)
        metadata = json.loads(response.candidates[0].content.parts[0].text)
        # You might need to further process 'metadata' to extract the exact values

        # Create a new document in Firestore
        doc_ref = db.collection("clothes").document()
        doc_ref.set({
            "image_url": blob.public_url,
            "clothing_type": metadata.get("clothing_type", ""),
            "color": metadata.get("color", ""),
            "style": metadata.get("style", ""),
            "material": metadata.get("material", ""),
            "occasion": metadata.get("occasion", "")
        })
        # convert the doc_ref into json syntax
        j = json.dumps(doc_ref.get().to_dict())
        return j, 200

    except Exception as e:
        print(f"Error adding metadata: {e}")





if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))

