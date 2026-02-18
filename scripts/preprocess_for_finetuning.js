
const admin = require('../functions/node_modules/firebase-admin');
const fs = require('fs');
const path = require('path');
const serviceAccount = require('./service-account.json');

if (!admin.apps.length) {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
}

const db = admin.firestore();
const OUTPUT_FILE = path.join(__dirname, '../training_data.jsonl');

async function preprocess() {
    console.log('--- 데이터 전처리 시작 (Firestore -> JSONL) ---');

    try {
        // goal이 있고 test 데이터가 아닌 것만 가져옴
        const snapshot = await db.collection('synthetic_conversations')
            .where('goal', '!=', null)
            .get();

        console.log(`총 ${snapshot.size}건의 데이터 발견.`);

        let processedCount = 0;
        const writeStream = fs.createWriteStream(OUTPUT_FILE);

        snapshot.forEach(doc => {
            const data = doc.data();
            if (data.test) return;

            const conversation = data.conversation || data.messages || [];
            if (conversation.length < 2) return;

            // Use textInput and output for maximum compatibility with tunedModels API
            const history = conversation.slice(0, -1);
            const lastTurn = conversation[conversation.length - 1];

            // Ensure the last turn is from the coach/model
            if (lastTurn.role === 'user' || lastTurn.sender === 'user') return;

            const textInput = history.map(msg => {
                const roleName = (msg.role === 'user' || msg.sender === 'user') ? '사용자' : '코치';
                return `${roleName}: ${msg.text}`;
            }).join('\n');

            const output = lastTurn.text;

            writeStream.write(JSON.stringify({ textInput, output }) + '\n');
            processedCount++;
        });

        writeStream.end();
        console.log(`\n전처리 완료!`);
        console.log(`파일 위치: ${OUTPUT_FILE}`);
        console.log(`저장된 유효 데이터: ${processedCount}건`);

    } catch (error) {
        console.error('전처리 중 오류 발생:', error);
    } finally {
        // FireStore 연결 종료를 위해 약간의 대기 후 종료
        setTimeout(() => process.exit(0), 1000);
    }
}

preprocess();
