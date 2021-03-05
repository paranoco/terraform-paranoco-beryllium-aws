const util = require('util');
const AWS = require('aws-sdk');
const cloudWatchLogs = new AWS.CloudWatchLogs();

const AWS_CLOUDWATCH_RETENTION_IN_DAYS = 90;

async function updateRetentionPolicy(logGroupName) {
	await cloudWatchLogs.putRetentionPolicy({
		logGroupName,
		retentionInDays: AWS_CLOUDWATCH_RETENTION_IN_DAYS
	})
	.promise()
	
	console.info(`set log group [${logGroupName}] retention to [${AWS_CLOUDWATCH_RETENTION_IN_DAYS}]`);
}

exports.handler = async (event) => {
    await updateRetentionPolicy(event.detail.requestParameters.logGroupName);
};
