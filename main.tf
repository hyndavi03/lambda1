provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "example" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "MYVPC"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.example.id
  cidr_block = var.public_subnet_cidr_block
  tags = {
    Name = "PUBLIC-SUB"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.example.id
  cidr_block = var.private_subnet_cidr_block
  tags = {
    Name = "PRIVATE-SUB"
  }
}

resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
  tags = {
    Name = "INGW"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example.id
  }
  tags = {
    Name = "RTB"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_nat_gateway" "example" {
  allocation_id = aws_eip.example.id
  subnet_id     = aws_subnet.public.id
  tags = {
    Name = "NATGW"
  }
}

resource "aws_eip" "example" {}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}"  # Path to the directory containing your Lambda code
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "example" {
  function_name = "MyLambdafunction"
  filename      = data.archive_file.lambda_zip.output_path
  role          = aws_iam_role.lambda_exec.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda-exec-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

terraform {
  backend "s3" {
    bucket = "terraformstatfile"  # Replace with your bucket name
    key    = "terraform.tfstate"
    region = "us-east-1"  # Replace with your preferred region
  }
}
