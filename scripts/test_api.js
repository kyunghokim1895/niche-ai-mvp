
const { GoogleGenerativeAI } = require("../functions/node_modules/@google/generative-ai");
const API_KEY = "AIzaSyAWAIDsynNaeJ3teqGDXk75McSJdnTB6RI";
const genAI = new GoogleGenerativeAI(API_KEY);

async function test() {
    try {
        console.log("Listing models...");
        // Use the proper SDK listModels if available, or fetch manually
        const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models?key=${API_KEY}`);
        const data = await response.json();

        if (data.models) {
            console.log("Available Models:");
            data.models.forEach(m => {
                console.log(`- ${m.name} (v1beta)`);
            });
        } else {
            console.log("No models found or error:", JSON.stringify(data));
        }

        const responseV1 = await fetch(`https://generativelanguage.googleapis.com/v1/models?key=${API_KEY}`);
        const dataV1 = await responseV1.json();
        if (dataV1.models) {
            console.log("\nAvailable Models (v1):");
            dataV1.models.forEach(m => {
                console.log(`- ${m.name} (v1)`);
            });
        }

    } catch (e) {
        console.log(`❌ ERROR: ${e.message}`);
    }
}

test();
