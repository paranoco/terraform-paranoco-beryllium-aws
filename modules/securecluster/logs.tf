data "archive_file" "SubscribeLogGroupToLogDNA" {
  type        = "zip"
  output_path = "${path.module}/files/SubscribeLogGroupToLogDNA.zip"

  source_dir = "${path.module}/lambdasrc/SubscribeLogGroupToLogDNA/"
}

// lambda to subscribe
resource "aws_iam_role" "SubscribeLogGroupToLogDNA" {
  name = "SubscribeLogGroupToLogDNA"
  path = "/service-role/${var.paranoco_arch_version}/"

  inline_policy {
    name = "allow_subscribe"

    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "AllowPutSubscriptionFilter",
          "Effect" : "Allow",
          "Action" : "logs:PutSubscriptionFilter",
          "Resource" : "*"
        }
      ]
    })
  }

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Effect" : "Allow",
        "Sid" : ""
      }
    ]
  })
}

resource "aws_lambda_function" "SubscribeLogGroupToLogDNA" {
  filename      = data.archive_file.SubscribeLogGroupToLogDNA.output_path
  function_name = "${var.paranoco_arch_version}_SubscribeLogGroupToLogDNA"
  role          = aws_iam_role.SubscribeLogGroupToLogDNA.arn
  handler       = "index.handler"

  source_code_hash = filebase64sha256(data.archive_file.SubscribeLogGroupToLogDNA.output_path)

  runtime = "nodejs14.x"

  environment {
    variables = {
      DESTINATION_LAMBDA_ARN = aws_lambda_function.CloudwatchLogsToLogDNA.arn
    }
  }
}

resource "aws_lambda_permission" "SubscribeLogGroupToLogDNA_CloudWatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.SubscribeLogGroupToLogDNA.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.OnCreateLogGroup.arn
}


// #### ------ lambda to forward

data "archive_file" "CloudwatchLogsToLogDNA" {
  type        = "zip"
  output_path = "${path.module}/files/CloudwatchLogsToLogDNA.zip"
  source_dir  = "${path.module}/lambdasrc/CloudwatchLogsToLogDNA/"
  excludes = [
    "package.json",
    "package-lock.json",
    "yarn.lock"
  ]
}
resource "aws_iam_role" "CloudwatchLogsToLogDNA" {
  name = "CloudwatchLogsToLogDNA"
  path = "/service-role/${var.paranoco_arch_version}/"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Effect" : "Allow",
        "Sid" : ""
      }
    ]
  })

}

resource "aws_lambda_function" "CloudwatchLogsToLogDNA" {
  filename      = data.archive_file.CloudwatchLogsToLogDNA.output_path
  function_name = "${var.paranoco_arch_version}_CloudwatchLogsToLogDNA"
  role          = aws_iam_role.CloudwatchLogsToLogDNA.arn
  handler       = "index.handler"

  source_code_hash = filebase64sha256(data.archive_file.CloudwatchLogsToLogDNA.output_path)

  runtime = "nodejs14.x"

  environment {
    variables = {
      LOGDNA_KEY = "de7a09c71d48c823673ac64660baab9b"
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_lambda_permission" "CloudwatchLogsToLogDNA_CloudWatch" {
  statement_id  = "InvokePermissionsForAllLogGroups"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.CloudwatchLogsToLogDNA.function_name
  principal     = "logs.amazonaws.com"
  source_arn    = "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:log-group:*:*" //TODO
}

// --- lambda for retention

data "archive_file" "SetLogGroupRetention" {
  type        = "zip"
  output_path = "${path.module}/files/SetLogGroupRetention.zip"
  source_dir  = "${path.module}/lambdasrc/SetLogGroupRetention/"
  excludes = [
    "package.json",
    "package-lock.json",
    "yarn.lock"
  ]
}

resource "aws_iam_role" "SetLogGroupRetention" {
  name = "SetLogGroupRetention"
  path = "/service-role/${var.paranoco_arch_version}/"

  inline_policy {
    name = "allow_subscribe"

    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "AllowPutRetentionPolicy",
          "Effect" : "Allow",
          "Action" : "logs:PutRetentionPolicy",
          "Resource" : "*"
        }
      ]
    })
  }

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Effect" : "Allow",
        "Sid" : ""
      }
    ]
  })
}

resource "aws_lambda_function" "SetLogGroupRetention" {
  filename      = data.archive_file.SetLogGroupRetention.output_path
  function_name = "${var.paranoco_arch_version}_SetLogGroupRetention"
  role          = aws_iam_role.SetLogGroupRetention.arn
  handler       = "index.handler"

  source_code_hash = filebase64sha256(data.archive_file.SetLogGroupRetention.output_path)

  runtime = "nodejs14.x"
}

resource "aws_lambda_permission" "SetLogGroupRetention_CloudWatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.SetLogGroupRetention.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.OnCreateLogGroup.arn
}

/// ### --- event configuration ---

resource "aws_cloudwatch_event_rule" "OnCreateLogGroup" {
  name        = "${var.paranoco_arch_version}_OnCreateLogGroup"
  description = "OnCreateLogGroup"

  event_pattern = jsonencode({
    "detail-type" : [
      "AWS API Call via CloudTrail"
    ],
    "source" : [
      "aws.logs"
    ],
    "detail" : {
      "eventSource" : [
        "logs.amazonaws.com"
      ],
      "eventName" : [
        "CreateLogGroup"
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "OnCreateLogGroup_SubscribeLogGroupToLogDNA" {
  rule = aws_cloudwatch_event_rule.OnCreateLogGroup.name
  arn  = aws_lambda_function.SubscribeLogGroupToLogDNA.arn
}

resource "aws_cloudwatch_event_target" "OnCreateLogGroup_SetLogGroupRetention" {
  rule = aws_cloudwatch_event_rule.OnCreateLogGroup.name
  arn  = aws_lambda_function.SetLogGroupRetention.arn
}
