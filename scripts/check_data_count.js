const admin = require("../functions/node_modules/firebase-admin");
const serviceAccount = require("./service-account.json");
const path = require('path');
require('../functions/node_modules/dotenv').config({ path: path.join(__dirname, '../functions/.env') });

try {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
} catch (e) {
    if (e.code !== 'app/duplicate-app') console.error("Firebase Auth Error:", e);
}

const db = admin.firestore();

async function checkCount() {
    try {
        console.log("Checking actual database count...");

        // Method 1: Count aggregation (Fast, cheap)
        const snapshot = await db.collection('synthetic_conversations').count().get();
        console.log(`\n[Real-time Count] Total Records: ${snapshot.data().count}`);

        // Method 2: List last few IDs (Verification)
        const lastFew = await db.collection('synthetic_conversations')
            .orderBy('created_at', 'desc')
            .limit(3)
            .get();

        if (!lastFew.empty) {
            console.log("\n[Latest 3 Entries]");
            lastFew.forEach(doc => {
                const data = doc.data();
                const createdAt = data.created_at ? data.created_at.toDate().toISOString() : 'N/A';
                console.log(`- [${createdAt}] ID: ${doc.id} | Goal: ${data.goal} | ${data.user_persona} vs ${data.admin_persona}`);
            });
        }

    } catch (error) {
        console.log("Error counting documents:", error.message);
    }
}

checkCount();
