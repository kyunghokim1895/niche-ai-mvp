
const { google } = require('./functions/node_modules/googleapis');
const serviceAccount = require('./scripts/service-account.json');

async function checkBilling() {
    const auth = new google.auth.JWT(
        serviceAccount.client_email,
        null,
        serviceAccount.private_key,
        ['https://www.googleapis.com/auth/cloud-platform']
    );

    const billing = google.cloudbilling({ version: 'v1', auth });
    const projectName = `projects/${serviceAccount.project_id}`;

    try {
        const res = await billing.projects.getBillingInfo({ name: projectName });
        console.log('--- Billing Information ---');
        console.log(`Project: ${res.data.name}`);
        console.log(`Billing Enabled: ${res.data.billingEnabled}`);
        console.log(`Billing Account Name: ${res.data.billingAccountName || 'None'}`);
    } catch (err) {
        console.error('❌ Billing 정보를 가져오는 중 오류 발생:', err.message);
        if (err.message.includes('permission')) {
            console.log('💡 서비스 계정에 "Billing Account Viewer" 또는 "Project Viewer" 권한이 없을 수 있습니다.');
        }
    }
}

checkBilling();
