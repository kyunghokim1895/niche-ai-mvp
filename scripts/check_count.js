
const admin = require('../functions/node_modules/firebase-admin');
const serviceAccount = require('./service-account.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function check() {
    try {
        const snapshot = await db.collection('synthetic_conversations').count().get();
        console.log('COUNT:' + snapshot.data().count);
        process.exit(0);
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
}

check();
