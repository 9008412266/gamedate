################################################################################
# GameDate Platform — AWS Infrastructure (Terraform)
# Provisions: VPC, ECS Cluster, RDS, ElastiCache, S3, CloudFront, ALB
################################################################################

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "gamedate-terraform-state"
    key    = "production/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}

# ── Variables ────────────────────────────────────────────────
variable "aws_region"       { default = "us-east-1" }
variable "environment"      { default = "production" }
variable "app_name"         { default = "gamedate" }
variable "db_password"      { sensitive = true }
variable "jwt_secret"       { sensitive = true }

# ── VPC ─────────────────────────────────────────────────────
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.app_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = false  # HA: one per AZ
  enable_dns_hostnames = true

  tags = { Environment = var.environment, App = var.app_name }
}

# ── S3 Buckets ───────────────────────────────────────────────
resource "aws_s3_bucket" "media" {
  bucket = "${var.app_name}-media-${var.environment}"
}

resource "aws_s3_bucket_versioning" "media" {
  bucket = aws_s3_bucket.media.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_public_access_block" "media" {
  bucket                  = aws_s3_bucket.media.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── CloudFront (CDN) ─────────────────────────────────────────
resource "aws_cloudfront_origin_access_control" "media" {
  name                              = "${var.app_name}-media-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "media" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "GameDate Media CDN"

  origin {
    domain_name              = aws_s3_bucket.media.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.media.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.media.id
  }

  default_cache_behavior {
    target_origin_id       = "S3-${aws_s3_bucket.media.id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    min_ttl     = 0
    default_ttl = 86400   # 1 day
    max_ttl     = 31536000 # 1 year
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = { Environment = var.environment }
}

# ── RDS PostgreSQL ───────────────────────────────────────────
resource "aws_db_subnet_group" "main" {
  name       = "${var.app_name}-db-subnet-group"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_security_group" "rds" {
  name   = "${var.app_name}-rds-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
}

resource "aws_db_instance" "postgres" {
  identifier            = "${var.app_name}-postgres"
  engine                = "postgres"
  engine_version        = "16.1"
  instance_class        = "db.t3.medium"
  allocated_storage     = 100
  max_allocated_storage = 1000 # Auto-scaling up to 1TB
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "gamedate"
  username = "gamedate"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az               = true  # High availability
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  deletion_protection = true
  skip_final_snapshot = false
  final_snapshot_identifier = "${var.app_name}-final-snapshot"

  performance_insights_enabled = true

  tags = { Environment = var.environment }
}

# ── ElastiCache Redis ────────────────────────────────────────
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.app_name}-redis-subnet-group"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "${var.app_name}-redis"
  description                = "GameDate Redis Cluster"
  node_type                  = "cache.t3.medium"
  num_cache_clusters         = 2  # Primary + 1 replica
  parameter_group_name       = "default.redis7"
  port                       = 6379
  subnet_group_name          = aws_elasticache_subnet_group.main.name
  security_group_ids         = [aws_security_group.redis.id]
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  automatic_failover_enabled = true
  multi_az_enabled           = true

  tags = { Environment = var.environment }
}

resource "aws_security_group" "redis" {
  name   = "${var.app_name}-redis-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
}

# ── ECS Cluster ──────────────────────────────────────────────
resource "aws_ecs_cluster" "main" {
  name = "${var.app_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# ── Outputs ──────────────────────────────────────────────────
output "cloudfront_domain"     { value = aws_cloudfront_distribution.media.domain_name }
output "rds_endpoint"          { value = aws_db_instance.postgres.endpoint }
output "redis_endpoint"        { value = aws_elasticache_replication_group.redis.primary_endpoint_address }
output "ecs_cluster_name"      { value = aws_ecs_cluster.main.name }
output "vpc_id"                { value = module.vpc.vpc_id }
