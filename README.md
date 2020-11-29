About
==========================

I like Heroku as a first destination for new projects. Heroku has a couple addons for log management, but AWS CloudWatch Logs is a super low cost place for log files, and a relatively known quantity operationally.

There's no simple "select this addon" solution for Cloudwatch Logs from Heroku, but Heroku supports log "drains".

This lambda function acts as a Heroku log drain.

With a serverless solution I'm only charged for computing resources I use: important for situations where Heroku's free tier may power down the unused instance.

Using this lambda script
=========================

  1. Configure your terraform credentials 

  2. `make` creates the zip file for deployment.

  3. Run `cd terraform`

  4. Run `terraform apply` to create an s3 bucket, upload the zip file, provision the lambda function and expose it with an API endpoint

  5. Using the AWS lambda management console, find out the URL for the lambda.
  6. The lambda takes two path parameters at the end: these are the Cloudwatch Logs log group and log stream to write events to. Decide on these.
  7. `heroku drains:add https://{lambdaApiEndpoint}/Prod/flush/{logGroup}/{logStream}`

Testing deployment
========================

Visit the `/Prod/flush/test/testing` route and you should not get errors in the CloudWatch logs for the lambda function.


Credit:
==========================

  * [On aws cloudformation package and references in CodeURI](https://github.com/awslabs/serverless-application-model/issues/61#issuecomment-311066225)
  * Basis for Makefile: [jc2k's blog post on using make for Python Lambda functions](https://unrouted.io/2016/07/21/use-make/)
  * Basis for reading Heroku flush info: [Mischa Spiegelmock's Heroku logging to Slack implementation](https://spiegelmock.com/2017/10/26/heroku-logging-to-aws-lambda/)

Alternatives
=========================

If you want to avoid doing all this, consider [Logbox.io](https://logbox.io/?r=rwilcox), which provides a similar service but with less AWS fiddling. (Especially good if AWS isn't your primary cloud provider!)
