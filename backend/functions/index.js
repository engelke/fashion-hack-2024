const functions = require('@google-cloud/functions-framework');
const { Storage } = require('@google-cloud/storage');
const { VertexAI } = require('@google-cloud/vertexai');
const { marked } = require('marked');
const storage = new Storage();

// Get project ID from environment or default to the one from deploy.sh
const projectId = process.env.GOOGLE_CLOUD_PROJECT || 'fashion-hack-2024';
const location = 'us-central1';

// Initialize Vertex AI with explicit project ID
const vertexAI = new VertexAI({project: projectId, location: location});
const model = 'gemini-pro';

// Configure marked for safe HTML
marked.use({
  headerIds: false,
  mangle: false,
  breaks: true,
  gfm: true
});

functions.http('getSignedUrl', async (req, res) => {
  try {
    // Enable CORS
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST');
    res.set('Access-Control-Allow-Headers', 'Content-Type');

    // Handle preflight requests
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    const { bucket, filename } = req.query;
    if (!bucket || !filename) {
      res.status(400).send('Missing bucket or filename parameter');
      return;
    }

    const bucketInstance = storage.bucket(bucket);
    const file = bucketInstance.file(filename);

    const [signedUrl] = await file.getSignedUrl({
      version: 'v4',
      action: 'read',
      expires: Date.now() + 15 * 60 * 1000, // 15 minutes
    });

    res.json({ signedUrl });
  } catch (error) {
    console.error('Error generating signed URL:', error);
    res.status(500).send('Error generating signed URL');
  }
});

functions.http('getOutfitSuggestions', async (req, res) => {
  try {
    // Enable CORS
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST');
    res.set('Access-Control-Allow-Headers', 'Content-Type');

    // Handle preflight requests
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    const { item, expression, temperature, season } = req.query;
    if (!item || !expression || !temperature || !season) {
      res.status(400).send('Missing required parameters');
      return;
    }

    console.log('Using project:', projectId, 'in location:', location);

    const generativeModel = vertexAI.preview.getGenerativeModel({
      model: model,
      generation_config: {
        max_output_tokens: 2048,
        temperature: 0.9,
        top_p: 1,
      },
    });

    const prompt = `As a fashion expert, suggest outfit combinations for a ${expression} person wearing a ${item} in ${temperature} ${season} weather. Focus on creating stylish and practical outfits. Include specific suggestions for complementary pieces and accessories. Format your response in Markdown with:

- A brief introduction
- A bulleted list of 2-3 complete outfit suggestions
- A section for accessories and styling tips

Keep each suggestion concise but detailed.`;

    console.log('Sending prompt to Vertex AI:', prompt);

    const result = await generativeModel.generateContent({
      contents: [{ role: 'user', parts: [{ text: prompt }] }],
    });

    console.log('Received response from Vertex AI');

    const response = result.response;
    const markdownText = response.candidates[0].content.parts[0].text;
    
    // Convert Markdown to HTML
    const htmlContent = marked(markdownText);

    res.json({ 
      suggestions: markdownText,
      html: htmlContent 
    });
  } catch (error) {
    console.error('Error generating outfit suggestions:', error);
    res.status(500).json({
      error: 'Error generating outfit suggestions',
      details: error.message,
      project: projectId,
      location: location
    });
  }
}); 