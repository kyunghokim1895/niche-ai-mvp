
const admin = require('../functions/node_modules/firebase-admin');
const serviceAccount = require('./service-account.json');

if (!admin.apps.length) {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
}

const db = admin.firestore();

async function inspectSamples(limit = 3) {
    console.log(`--- 무작위 품질 검수 시작 (실제 대화 샘플 ${limit}건) ---\n`);

    try {
        // goal 필드가 있는 실제 데이터만 쿼리 (Index 필요할 수 있음, 없으면 에러 메시지 확인)
        let query = db.collection('synthetic_conversations')
            .where('goal', '!=', null)
            .limit(limit);

        const snapshot = await query.get();

        if (snapshot.empty) {
            console.log('데이터가 없습니다. (필터 조건 확인 필요)');
            return;
        }

        snapshot.forEach(doc => {
            const data = doc.data();
            if (data.test) return; // Skip test records

            console.log(`[ID: ${doc.id}]`);

            const uPersona = data.userPersona || data.user_persona || 'Unknown';
            const aPersona = data.adminPersona || data.coach_persona || 'Unknown';
            const uType = typeof uPersona === 'string' ? uPersona : (uPersona.type || 'Unknown');
            const aType = typeof aPersona === 'string' ? aPersona : (aPersona.type || 'Unknown');

            console.log(`MBTI: ${uType} (User) vs ${aType} (Coach)`);
            console.log(`Goal: ${data.goal || 'N/A'}`);
            console.log(`--- 대화 내용 ---`);

            const conversation = data.conversation || data.messages || [];
            conversation.slice(0, 4).forEach(chat => {
                const role = chat.role || chat.sender || 'Unknown';
                const text = chat.text || '';
                console.log(`${role}: ${text.substring(0, 100)}${text.length > 100 ? '...' : ''}`);
            });
            console.log(`\n------------------------------------------------\n`);
        });

    } catch (error) {
        if (error.message.includes('index')) {
            console.log('인덱스가 필요합니다. 단순 쿼리로 전환합니다...');
            const simpleSnapshot = await db.collection('synthetic_conversations').limit(20).get();
            let count = 0;
            simpleSnapshot.forEach(doc => {
                const data = doc.data();
                if (data.goal && !data.test && count < limit) {
                    printDoc(doc);
                    count++;
                }
            });
        } else {
            console.error('검수 중 오류 발생:', error);
        }
    } finally {
        process.exit(0);
    }
}

function printDoc(doc) {
    const data = doc.data();
    console.log(`[ID: ${doc.id}]`);
    const uPersona = data.userPersona || data.user_persona || 'Unknown';
    const aPersona = data.adminPersona || data.coach_persona || 'Unknown';
    const uType = typeof uPersona === 'string' ? uPersona : (uPersona.type || 'Unknown');
    const aType = typeof aPersona === 'string' ? aPersona : (aPersona.type || 'Unknown');
    console.log(`MBTI: ${uType} (User) vs ${aType} (Coach)`);
    console.log(`Goal: ${data.goal || 'N/A'}`);
    console.log(`--- 대화 내용 ---`);
    const conversation = data.conversation || data.messages || [];
    conversation.slice(0, 4).forEach(chat => {
        const role = chat.role || chat.sender || 'Unknown';
        const text = chat.text || '';
        console.log(`${role}: ${text.substring(0, 100)}${text.length > 100 ? '...' : ''}`);
    });
    console.log(`\n------------------------------------------------\n`);
}

inspectSamples();
