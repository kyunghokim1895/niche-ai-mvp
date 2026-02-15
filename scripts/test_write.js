const admin = require("../functions/node_modules/firebase-admin");
const serviceAccount = require("./service-account.json");

console.log("Connecting using Service Account for Write Test:", serviceAccount.project_id);

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function testWrite() {
    try {
        console.log("Writing test document to 'synthetic_conversations'...");
        const res = await db.collection('synthetic_conversations').add({
            test: true,
            created_at: admin.firestore.FieldValue.serverTimestamp(),
            message: "Test Write from Script",
            timestamp: new Date().toISOString()
        });
        console.log("Write Successful! ✅");
        console.log("Document ID:", res.id);
    } catch (error) {
        console.error("Error writing to Firestore:", error);
    }
}

testWrite();
