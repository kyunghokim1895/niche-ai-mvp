
const { GoogleGenerativeAI } = require("../functions/node_modules/@google/generative-ai");
const path = require('path');
require('../functions/node_modules/dotenv').config({ path: path.join(__dirname, '../functions/.env') });

const API_KEY = process.env.GEMINI_API_KEY;
if (!API_KEY) {
    console.error("No API KEY found.");
    process.exit(1);
}

const genAI = new GoogleGenerativeAI(API_KEY);

async function listModels() {
    try {
        // Note: listModels is not directly exposed in the high-level helper of SDK v0.1.3 easily, 
        // but in newer versions it might be via ModelManager. 
        // However, the simplest way to check connection is to try a very basic model name like 'gemini-1.5-flash-latest' or 'gemini-1.0-pro'.
        // Let's try to just run a simple generateContent with a fallback list to see which one works.

        const candidates = [
            "gemini-1.5-flash",
            "gemini-1.5-pro",
            "gemini-1.0-pro",
            "gemini-pro",
            "gemini-1.5-flash-latest"
        ];

        console.log("Testing models...");

        for (const modelName of candidates) {
            process.stdout.write(`Testing ${modelName}: `);
            try {
                const model = genAI.getGenerativeModel({ model: modelName });
                const result = await model.generateContent("Hello");
                const response = await result.response;
                console.log("OK ✅");
                return; // Found one!
            } catch (e) {
                console.log(`Failed ❌ (${e.message.split('[')[0]})`);
            }
        }
        console.log("All models failed.");
    } catch (e) {
        console.error(e);
    }
}

listModels();
