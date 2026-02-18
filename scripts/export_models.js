
const fs = require('fs');
const API_KEY = "AIzaSyAWAIDsynNaeJ3teqGDXk75McSJdnTB6RI";

async function test() {
    try {
        const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models?key=${API_KEY}`);
        const data = await response.json();
        fs.writeFileSync('models_list.json', JSON.stringify(data, null, 2));
        console.log("Done! Check models_list.json");
    } catch (e) {
        console.log(`❌ ERROR: ${e.message}`);
    }
}

test();
