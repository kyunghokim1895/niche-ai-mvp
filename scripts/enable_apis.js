
const { google } = require('googleapis');
const serviceAccount = require('./service-account.json');

async function enableApis() {
    const auth = new google.auth.JWT(
        serviceAccount.client_email,
        null,
        serviceAccount.private_key,
        ['https://www.googleapis.com/auth/cloud-platform', 'https://www.googleapis.com/auth/service.management']
    );

    const serviceUsage = google.serviceusage({ version: 'v1', auth });
    const apis = [
        'aiplatform.googleapis.com',
        'generativelanguage.googleapis.com',
        'serviceusage.googleapis.com'
    ];

    console.log('--- API 활성화 시작 ---');

    for (const api of apis) {
        const name = `projects/${serviceAccount.project_id}/services/${api}`;
        console.log(`[시도] ${api} 활성화 중...`);
        try {
            const operation = await serviceUsage.services.enable({ name });
            console.log(`✅ ${api} 활성화 요청 성공 (Operation ID: ${operation.data.name})`);
        } catch (err) {
            console.error(`❌ ${api} 활성화 실패: ${err.message}`);
        }
    }
}

enableApis();
