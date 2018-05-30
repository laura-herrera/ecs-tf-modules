/* IAM role for executing lambda functions */
resource "aws_iam_role" "iam_for_lambda" {
  name = "${var.lambda_function_role_name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

/* Add an Inline Policy if needed */
resource "aws_iam_role_policy" "inline_policy" {
  count = "${var.add_inline_policy}"

  name = "${var.inline_policy_name}"
  role = "${aws_iam_role.iam_for_lambda.id}"

  policy = <<EOF
  "${var.inline_policy_content}"
EOF
}

/* Instance Role Policies Attachments if needed */
resource "aws_iam_role_policy_attachment" "policy_attach" {
  count = "${length(var.policies)}"

  role = "${aws_iam_role.iam_for_lambda.name}"
  policy_arn = "${element(var.policies, count.index)}"
}

/* The Lambda Function */
resource "aws_lambda_function" "lambda" {
  filename = "${var.lambda_file_name}"
  function_name = "${var.lambda_function_name}"
  role = "${aws_iam_role.iam_for_lambda.arn}"
  handler = "${var.lambda_function_handler}"
  source_code_hash = "${base64sha256(file("${var.lambda_file_name}"))}"
  runtime = "${var.lambda_function_runtime}"

  environment {
    variables = "${var.lambda_function_env_vars}"
  }
  tags {
    Name = "${var.cluster_name}-${var.environment}"
    Cluster = "${var.cluster_name}"
    Environment = "${var.environment}"
  }
}

