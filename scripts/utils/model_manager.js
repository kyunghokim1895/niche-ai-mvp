const fs = require('fs');
const path = require('path');

class ModelManager {
    constructor() {
        this.configPath = path.join(__dirname, '../../config/models_config.json');
        this.currentEnv = process.env.NODE_ENV || 'development';
        this.loadConfig();
    }

    loadConfig() {
        try {
            const data = fs.readFileSync(this.configPath, 'utf8');
            this.allConfigs = JSON.parse(data);
            this.config = this.allConfigs[this.currentEnv] || this.allConfigs['development'];
            console.log(`[ModelManager] Loaded config for environment: ${this.currentEnv}`);
        } catch (error) {
            console.error('[ModelManager] Error loading config:', error.message);
            // Minimal fallback
            this.config = {
                "DATA_GENERATOR": "gemini-2.0-flash",
                "AI_COACH_CHAT": "gemini-1.5-flash"
            };
        }
    }

    // Change environment on the fly (useful for testing)
    setEnv(env) {
        if (this.allConfigs[env]) {
            this.currentEnv = env;
            this.config = this.allConfigs[env];
            console.log(`[ModelManager] Switched to environment: ${this.currentEnv}`);
        } else {
            console.warn(`[ModelManager] Environment ${env} not found in config.`);
        }
    }

    getModel(role) {
        if (!this.config || !this.config[role]) {
            console.warn(`[ModelManager] No model assigned for role: ${role} in ${this.currentEnv}. Falling back to default.`);
            return "gemini-1.5-flash";
        }
        return this.config[role];
    }
}

module.exports = new ModelManager();
