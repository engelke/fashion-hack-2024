from flask import Flask, request, render_template, jsonify
from google.cloud import storage
import os
import uuid

app = Flask(__name__)

# Configure Cloud Storage client
storage_client = storage.Client()
bucket_name = os.environ.get("CLOUD_STORAGE_BUCKET") # Get bucket name from environment variable
if not bucket_name:
    raise ValueError("CLOUD_STORAGE_BUCKET environment variable not set.")
bucket = storage_client.bucket(bucket_name)

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



if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
