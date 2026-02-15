const path = require('path');
require('../functions/node_modules/dotenv').config({ path: path.join(__dirname, '../functions/.env') });

const API_KEY = process.env.GEMINI_API_KEY;
const MODEL_NAME = "gemini-flash-latest"; // Using the same model as the main script
const API_URL = `https://generativelanguage.googleapis.com/v1beta/models/${MODEL_NAME}:generateContent?key=${API_KEY}`;

async function testGemini() {
    console.log("Testing Gemini API...");
    console.log(`Model: ${MODEL_NAME}`);
    console.log(`API Key Loaded: ${API_KEY ? 'Yes' + ` (${API_KEY.substring(0, 5)}...)` : 'No'}`);

    const payload = {
        contents: [{
            parts: [{ text: "Hello, answer in one word." }]
        }]
    };

    try {
        const response = await fetch(API_URL, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });

        console.log(`Response Status: ${response.status} ${response.statusText}`);

        if (!response.ok) {
            const errText = await response.text();
            console.error("Error Body:", errText);
            return;
        }

        const data = await response.json();
        console.log("Response Data:", JSON.stringify(data, null, 2));

        if (data.candidates && data.candidates[0].content) {
            console.log("✅ Success! Content:", data.candidates[0].content.parts[0].text);
        } else {
            console.log("❌ Partial Success (No content generated).");
        }

    } catch (error) {
        console.error("Request Failed:", error);
    }
}

testGemini();
