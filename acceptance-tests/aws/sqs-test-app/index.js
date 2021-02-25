const vcapServices = require('vcap_services');
const AWS = require('aws-sdk')
const restify = require('restify');

function runServer(content) {
    const server = restify.createServer();
    server.get('/', (_, res, next) => {
        res.send(content)
        next()
    });

    server.listen(process.env.PORT || 8080, function () {
        console.log('%s listening at %s', server.name, server.url);
    });
}

let credentials = vcapServices.findCredentials({ instance: { tags: 'SQS' } });

if (Object.keys(credentials).length > 0) {
    AWS.config.credentials = {
        region: credentials.region_name,
    }
    queue_url = credentials.url

    sqs = new AWS.SQS({ apiVersion: '2006-03-01' })
    sqs.listQueues({}, (err, data) => {
        if (err) {
            console.error("Failed listing queues", err)
        } else {
            if !data.QueueUrls.includes(queue_url) {
              console.error(`Failed to find queue with url ${queue_url}`, err)
            } else {
              runServer(data)
          }
        }
    })
} else {
    console.error("No SQS creds in vcap_services")
}

// push app with no-start, bind to a queue and then start. See what happens
