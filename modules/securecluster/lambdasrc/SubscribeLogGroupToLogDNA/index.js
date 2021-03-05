const util = require('util');
const AWS = require('aws-sdk');
const cloudWatchLogs = new AWS.CloudWatchLogs();

const DESTINATION_LAMBDA_ARN = process.env.DESTINATION_LAMBDA_ARN;
const DESTINATION_LAMBDA_ARNParts = DESTINATION_LAMBDA_ARN.split(":");
const FUNCTION_NAME = DESTINATION_LAMBDA_ARNParts[DESTINATION_LAMBDA_ARNParts.length-1];

const AWS_CLOUDWATCH_RETENTION_IN_DAYS = 90;

async function subscribeToLogGroup(logGroupName) {
    const logGroupNameParts = logGroupName.split(":")
    const logGroupShortName = logGroupNameParts[logGroupNameParts.length-1];
    const filterPattern = "";

	const req = {
		destinationArn: DESTINATION_LAMBDA_ARN,
		logGroupName: logGroupName,
		filterName: `${logGroupShortName}To${FUNCTION_NAME}`,
		filterPattern: filterPattern
	};

	try {
		await cloudWatchLogs
			.putSubscriptionFilter(req)
			.promise()
		
		console.info(`subscribed log group [${logGroupName}] to [${DESTINATION_LAMBDA_ARN}]`);
	} catch (err) {
		console.info(`error PutSubscriptionFilter: ${err}`);
		throw errl;
	}
}

exports.handler = async (event) => {
    await subscribeToLogGroup(event.detail.requestParameters.logGroupName);
};