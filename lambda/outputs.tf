output "lambda_function_arn" {
  value = "${aws_lambda_function.lambda.arn}"
}
output "lambda_function_version" {
  value = "${aws_lambda_function.lambda.version}"
}
output "lambda_function_last_modified" {
  value = "${aws_lambda_function.lambda.last_modified}"
}
