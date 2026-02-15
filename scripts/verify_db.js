const admin = require("../functions/node_modules/firebase-admin");
const serviceAccount = require("./service-account.json");

console.log("Connecting using Service Account for Project:", serviceAccount.project_id);

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function listCollections() {
    try {
        const collections = await db.listCollections();
        console.log("\n--- Firestore Collections Found ---");
        if (collections.length === 0) {
            console.log("No collections found.");
        } else {
            for (const col of collections) {
                console.log(`- Collection: '${col.id}'`);

                // Try to count documents in each collection
                const snapshot = await col.limit(1).get();
                if (!snapshot.empty) {
                    console.log(`  (Contains data ✅)`);
                } else {
                    console.log(`  (Empty ❌)`);
                }
            }
        }
        console.log("-----------------------------------");
    } catch (error) {
        console.error("Error listing collections:", error);
    }
}

listCollections();
