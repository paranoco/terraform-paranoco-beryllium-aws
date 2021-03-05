const https = require('https');

/**
 * Do a request with options provided.
 *
 * @param {Object} options
 * @param {Object} data
 * @return {Promise} a promise of request
 */
function doRequest(options, data) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      res.setEncoding('utf8');
      let responseBody = '';

      res.on('data', (chunk) => {
        responseBody += chunk;
      });

      res.on('end', () => {
        resolve(responseBody);
      });
    });

    req.on('error', (err) => {
      reject(err);
    });

    req.write(data)
    req.end();
  });
}

async function sendToSlack(channel, txt) {
  const msg = {
    "channel": channel,
    "username": "AWS",
    "text": "```" + txt + "```",
    "icon_emoji": ""
  }
  
  console.log("logging", msg);
  
  const body = await doRequest({
    hostname: "hooks.slack.com", 
    path: "/services/T070DCWGK/B01MXPAGSTZ/hhSmaizUXhliKDCFU2dStsrU",
    method: "POST"
  }, Buffer.from(JSON.stringify(msg), "utf8"));
  
  console.log(body);
  
  return true;
}

async function processSNSMessage(topic, record) {
  if (record["detail-type"] == "ECS Task State Change") {
    return false;
  }
  
  const outRecord = {
    ...record,
    version: undefined,
    id: undefined,
    account: undefined,
    region: undefined,
    detail: {
      ...record.detail,
      createdAt: undefined,
      eventType: undefined,
      clusterArn: undefined,
      capacityProviderArns: undefined
    }
  }
  const channel = "#ops";
  return sendToSlack(channel, JSON.stringify(outRecord, null, 2));
}

exports.handler = async function(event, context) {
  event["Records"].forEach((record) => {
    processSNSMessage(record["Sns"]["TopicArn"], JSON.parse(record["Sns"]["Message"]))
  });
  return true;
}

