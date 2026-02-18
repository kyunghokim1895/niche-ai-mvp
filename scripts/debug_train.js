
const fs = require('fs');
const path = require('path');
require('../functions/node_modules/dotenv').config({ path: path.join(__dirname, '../functions/.env') });

const API_KEY = process.env.GEMINI_API_KEY;
const DATA_FILE = path.join(__dirname, '../training_data.jsonl');

const logPath = path.join(__dirname, '../debug_tuning.log');
const log = (msg) => {
    console.log(msg);
    fs.appendFileSync(logPath, msg + '\n');
};

async function debugTuning() {
    fs.writeFileSync(logPath, `--- Tuning Debug Started at ${new Date().toISOString()} ---\n`);

    if (!API_KEY) {
        log('ERROR: GEMINI_API_KEY가 없습니다.');
        return;
    }

    log('데이터 로드 중...');
    const lines = fs.readFileSync(DATA_FILE, 'utf8').split('\n').filter(line => line.trim());
    const examples = lines.map(line => JSON.parse(line)).slice(0, 25); // Just 25 for fast test

    log(`준비된 데이터: ${examples.length}건`);

    const baseModels = [
        "models/gemini-1.5-flash-001",
        "models/gemini-1.5-pro-002"
    ];

    for (const baseModel of baseModels) {
        log(`\n[시도] 베이스 모델: ${baseModel}...`);

        const payload = {
            displayName: `Debug-${Date.now()}`,
            baseModel: baseModel,
            tuningTask: {
                hyperparameters: { batchSize: 4, learningRate: 0.001, epochCount: 3 },
                trainingData: { examples: { examples: examples } }
            }
        };

        const url = `https://generativelanguage.googleapis.com/v1beta/tunedModels?key=${API_KEY}`;

        try {
            const response = await fetch(url, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });

            const result = await response.json();
            log(`Status: ${response.status}`);
            if (response.ok) {
                log(`✅ 성공! 리소스: ${result.name}`);
                break;
            } else {
                log(`❌ 실패: ${JSON.stringify(result, null, 2)}`);
            }
        } catch (error) {
            log(`⚠️ 오류: ${error.message}`);
        }
    }
}

debugTuning();
