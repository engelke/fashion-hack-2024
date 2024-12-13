const { VertexAI } = require('@google-cloud/vertexai');

// Initialize Vertex AI
const vertex_ai = new VertexAI({
  project: process.env.GOOGLE_CLOUD_PROJECT,
  location: 'us-central1',
});

// Use Gemini Pro model
const model = 'gemini-pro';

exports.getOutfitSuggestions = async (req, res) => {
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  
  if (req.method === 'OPTIONS') {
    res.set('Access-Control-Allow-Methods', 'GET');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    res.status(204).send('');
    return;
  }

  try {
    const { item, expression, temperature, season } = req.query;
    
    if (!item || !expression || !temperature || !season) {
      res.status(400).json({ error: 'Missing required parameters' });
      return;
    }

    // Construct the prompt with more context and structure
    const prompt = `You are a professional fashion stylist with expertise in creating modern, trendy outfits. 
    Create a complete outfit suggestion based on:
    - Main piece: ${item}
    - Expression style: ${expression}
    - Temperature: ${temperature}
    - Season: ${season}

    Provide a detailed outfit suggestion in the following format:

    STYLING THE MAIN PIECE:
    [Explain how to style the ${item} specifically]

    COMPLETE OUTFIT:
    - Top: [if main piece isn't a top]
    - Bottom: [if main piece isn't a bottom]
    - Layering: [any additional layers]
    - Footwear: [shoe recommendation]

    ACCESSORIES:
    - Jewelry: [specific recommendations]
    - Bag: [specific type and style]
    - Other: [any other accessories]

    STYLING TIPS:
    [3-4 specific tips about proportions, color combinations, or styling tricks]

    OCCASION VERSATILITY:
    [Brief note on how to adapt this outfit for different occasions]

    Focus on current fashion trends and ensure all suggestions are weather-appropriate for ${temperature} ${season} conditions.
    Consider the ${expression} expression style throughout all recommendations.`;

    // Get model response with higher temperature for more creative suggestions
    const generativeModel = vertex_ai.preview.getGenerativeModel({
      model: model,
      temperature: 0.7,
      topK: 40,
      topP: 0.8,
      maxOutputTokens: 1024,
    });

    const result = await generativeModel.generateText({
      prompt: prompt,
    });

    const response = result.response;

    res.status(200).json({
      suggestions: response.text,
    });

  } catch (error) {
    console.error('Error generating outfit suggestions:', error);
    res.status(500).json({ error: 'Failed to generate outfit suggestions' });
  }
}; 