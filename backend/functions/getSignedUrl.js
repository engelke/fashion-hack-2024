const { Storage } = require('@google-cloud/storage');
const storage = new Storage();
const cors = require('cors')({ origin: true });

exports.getSignedUrl = async (req, res) => {
  // Set CORS headers
  res.set('Access-Control-Allow-Origin', 'https://fashion-hack-348449317363.us-central1.run.app');
  res.set('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Cache-Control');
  
  // Handle preflight request
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    const { bucket, filename } = req.query;
    
    if (!bucket || !filename) {
      res.status(400).send('Missing bucket or filename parameter');
      return;
    }

    // Configure options for signed URL
    const options = {
      version: 'v4',
      action: 'read',
      expires: Date.now() + 15 * 60 * 1000, // URL expires in 15 minutes
    };

    // Generate signed URL
    const [url] = await storage
      .bucket(bucket)
      .file(filename)
      .getSignedUrl(options);

    res.status(200).json({ signedUrl: url });
  } catch (error) {
    console.error('Error generating signed URL:', error);
    res.status(500).send('Error generating signed URL');
  }
}; 