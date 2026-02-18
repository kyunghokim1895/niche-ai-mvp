
const fs = require('fs');
const path = require('path');
require('../functions/node_modules/dotenv').config({ path: path.join(__dirname, '../functions/.env') });

const API_KEY = process.env.GEMINI_API_KEY;
const DATA_FILE = path.join(__dirname, '../training_data.jsonl');

async function createTunedModel() {
    console.log('--- Gemini 파인튜닝 학습 요청 시작 (자동 최적화 모드) ---');

    if (!API_KEY) {
        console.error('ERROR: GEMINI_API_KEY가 없습니다.');
        return;
    }

    console.log('데이터 로드 및 형식 검사 중...');
    const lines = fs.readFileSync(DATA_FILE, 'utf8').split('\n').filter(line => line.trim());
    const examples = lines.map(line => {
        try {
            return JSON.parse(line);
        } catch (e) {
            console.warn('JSON 파싱 오류 스킵:', line.substring(0, 50));
            return null;
        }
    }).filter(e => e);

    // API 직접 전송은 대략 500~1000건 이내가 안전합니다.
    const MAX_EXAMPLES = 500;
    const trainExamples = examples.slice(0, MAX_EXAMPLES);
    console.log(`준비된 데이터: ${examples.length}건 중 ${trainExamples.length}건 사용 (API 한도 최적화)`);

    // 시도할 모델 이름 후보들
    const baseModels = [
        "models/gemini-1.5-flash-001",
        "models/gemini-1.0-pro-001",
        "models/gemini-1.5-pro-002"
    ];

    let success = false;
    for (const baseModel of baseModels) {
        if (success) break;

        console.log(`\n[시도] 베이스 모델: ${baseModel}...`);

        const payload = {
            displayName: `NicheAI-Coach-${Date.now()}`,
            baseModel: baseModel,
            tuningTask: {
                hyperparameters: {
                    batchSize: 4,
                    learningRate: 0.001,
                    epochCount: 3
                },
                trainingData: {
                    examples: {
                        examples: trainExamples
                    }
                }
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

            if (response.ok) {
                console.log(`✅ 성공! 모델 학습이 시작되었습니다.`);
                console.log(`모델 리소스: ${result.name}`);
                success = true;
            } else {
                console.error(`❌ 실패 (${baseModel}): ${result.error?.message || '알 수 없는 오류'}`);
                console.error('상세 오류:', JSON.stringify(result, null, 2));
            }
        } catch (error) {
            console.error(`⚠️ 네트워크 오류 (${baseModel}): ${error.message}`);
        }
    }

    if (!success) {
        console.log('\n--- 모든 API 요청이 실패했습니다 ---');
        console.log('원인 분석 및 조치:');
        console.log('1. 현재 API 환경에서 1.5 계열의 파인튜닝이 아직 v1beta에 활성화되지 않았을 수 있습니다.');
        console.log('2. 5,000건의 대량 데이터 학습은 [Google AI Studio](https://aistudio.google.com/app/tuned_models) 웹 사이트를 사용해 주세요.');
        console.log('   (웹사이트에서는 JSONL 파일을 직접 업로드하여 API 한도 이슈 없이 전체 데이터 학습이 가능합니다)');
    }
}

createTunedModel();
