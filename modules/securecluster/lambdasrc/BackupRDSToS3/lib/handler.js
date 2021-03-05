const moment = require('moment')
const path = require('path')
const uploadS3 = require('./upload-s3')
const pgdump = require('./pgdump')

const DEFAULT_CONFIG = {
    S3_REGION: 'eu-west-1',
    PGDUMP_PATH: path.join(__dirname, '../bin/postgres-12.6'),
    // maximum time allowed to connect to postgres before a timeout occurs
    PGCONNECT_TIMEOUT: 15
}

function generateBackupPath(databaseName, rootPath, now = null) {
    now = now || moment().utc()
    const timestamp = moment(now).format('DD-MM-YYYY@HH-mm-ss')
    const day = moment(now).format('YYYY-MM-DD')
    const filename = `${databaseName}-${timestamp}.backup`
    const key = path.join(rootPath || '', day, filename)
    return key
}

async function backup(config) {
    if (!config.PGDATABASE) {
        throw new Error('PGDATABASE not provided in the event data')
    }
    if (!config.S3_BUCKET) {
        throw new Error('S3_BUCKET not provided in the event data')
    }

    const key = generateBackupPath(
        config.PGDATABASE,
        config.ROOT
    )

    // spawn the pg_dump process
    let stream = await pgdump(config)
    // stream the backup to S3
    return uploadS3(stream, config, key)
}

async function handler(event) {
    try {
        const databaseBackupConfig = {
            ...DEFAULT_CONFIG,
            "PGDATABASE": process.env["DB_1_DATABASE"],
            "PGUSER": process.env["DB_1_USER"],
            "PGPASSWORD": process.env["DB_1_PASS"],
            "PGHOST": process.env["DB_1_HOST"],
            "S3_BUCKET" : process.env["S3_DESTINATION_BUCKET"],
            "ROOT": "daily-rds-backups"
        };
        
        return await backup(databaseBackupConfig)
    }
    catch (error) {
        // log the error and rethrow for Lambda
        if (process.env.NODE_ENV !== 'test') {
            console.error(error)
        }
        throw error
    }
}

module.exports = handler
