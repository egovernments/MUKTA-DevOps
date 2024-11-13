terraform {
  backend "s3" {
    bucket = "mukta-uat-terraform-state"
    key = "terraform"
    region = "ap-south-1"
  }
}

data "aws_caller_identity" "current" {}

data "tls_certificate" "thumb" {
  url = "${var.cluster_oidc_url}"
}

data "aws_ssm_parameter" "eks_ami" {
  name = "/aws/service/eks/optimized-ami/${var.kubernetes_version}/amazon-linux-2/recommended/image_id"
}

provider "kubernetes" {
  load_config_file = true
  config_path      = "/Users/shivam/.kube/mukta-uat"
  version          = "~> 1.11"
}

resource "aws_db_instance" "db" {
  allocated_storage                     = "25"
  availability_zone                     = "ap-south-1b"
  backup_retention_period               = "7"
  backup_target                         = "region"
  backup_window                         = "20:18-20:48"
  ca_cert_identifier                    = "rds-ca-rsa2048-g1"
  copy_tags_to_snapshot                 = "true"
  customer_owned_ip_enabled             = "false"
  db_name                               = "${var.db_name}"
  db_subnet_group_name                  = "db-subnet-group-mukta-uat"
  dedicated_log_volume                  = "false"
  deletion_protection                   = "false"
  engine                                = "postgres"
  engine_lifecycle_support              = "open-source-rds-extended-support"
  engine_version                        = "${var.db_version}"
  iam_database_authentication_enabled   = "false"
  identifier                            = "${var.cluster_name}-db"
  instance_class                        = "db.t4g.medium"
  iops                                  = "0"
  license_model                         = "postgresql-license"
  maintenance_window                    = "wed:12:36-wed:13:06"
  max_allocated_storage                 = "0"
  monitoring_interval                   = "0"
  multi_az                              = "false"
  network_type                          = "IPV4"
  option_group_name                     = "default:postgres-15"
  parameter_group_name                  = "default.postgres15"
  performance_insights_enabled          = "true"
  performance_insights_retention_period = "7"
  port                                  = "5432"
  publicly_accessible                   = "false"
  storage_encrypted                     = "false"
  storage_throughput                    = "0"
  storage_type                          = "gp3"
  skip_final_snapshot                   = "true"
  apply_immediately                     = "true"
  allow_major_version_upgrade           = "true"
  auto_minor_version_upgrade            = "false"

  tags = {
    KubernetesCluster = "${var.cluster_name}"
    Name              = "${var.cluster_name}-db"
    environment       = "${var.cluster_name}"
  }

  tags_all = {
    KubernetesCluster = "${var.cluster_name}"
    Name              = "${var.cluster_name}-db"
    environment       = "${var.cluster_name}"
  }

  username               = "${var.db_username}"
  vpc_security_group_ids = ["sg-0cd6088bc786c7e57"]
}


resource "aws_eks_cluster" "eks" {
  access_config {
    authentication_mode                         = "CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = "true"
  }

  bootstrap_self_managed_addons = "false"

  kubernetes_network_config {
    ip_family         = "ipv4"
    service_ipv4_cidr = "10.100.0.0/16"
  }

  name     = "${var.cluster_name}"
  role_arn = "arn:aws:iam::880678429748:role/mukta-uat2023042006164051890000000b"

  tags = {
    KubernetesCluster                 = "${var.cluster_name}"
    "kubernetes.io/cluster/mukta-uat" = "owned"
  }

  tags_all = {
    KubernetesCluster                 = "${var.cluster_name}"
    "kubernetes.io/cluster/mukta-uat" = "owned"
  }

  version = "${var.kubernetes_version}"

  vpc_config {
    endpoint_private_access = "false"
    endpoint_public_access  = "true"
    public_access_cidrs     = ["0.0.0.0/0"]
    security_group_ids      = ["sg-0ff6dc48f50dcca02"]
    subnet_ids              = ["subnet-071be1437a83e45f6", "subnet-081f414b49b1cbf99", "subnet-0a5a6062fc679e8ac", "subnet-0ff6ce7f80e4edd07"]
  }

  enabled_cluster_log_types     = []
}

resource "aws_launch_template" "launch_template" {
  name_prefix   = "${var.cluster_name}"
  image_id      = data.aws_ssm_parameter.eks_ami.value
  instance_type = "${var.instance_type}"
  update_default_version = "true"
  iam_instance_profile {
    arn = "arn:aws:iam::880678429748:instance-profile/mukta-uat20230420062506854600000019"
  }
  user_data = "IyEvYmluL2Jhc2ggLWUKCiMgQWxsb3cgdXNlciBzdXBwbGllZCBwcmUgdXNlcmRhdGEgY29kZQoKCiMgQm9vdHN0cmFwIGFuZCBqb2luIHRoZSBjbHVzdGVyCi9ldGMvZWtzL2Jvb3RzdHJhcC5zaCAtLWI2NC1jbHVzdGVyLWNhICdMUzB0TFMxQ1JVZEpUaUJEUlZKVVNVWkpRMEZVUlMwdExTMHRDazFKU1VNdmFrTkRRV1ZoWjBGM1NVSkJaMGxDUVVSQlRrSm5hM0ZvYTJsSE9YY3dRa0ZSYzBaQlJFRldUVkpOZDBWUldVUldVVkZFUlhkd2NtUlhTbXdLWTIwMWJHUkhWbnBOUWpSWVJGUkplazFFVVhsTlJFRXlUV3BGZDA5R2IxaEVWRTE2VFVSUmVFNTZRVEpOYWtWM1QwWnZkMFpVUlZSTlFrVkhRVEZWUlFwQmVFMUxZVE5XYVZwWVNuVmFXRkpzWTNwRFEwRlRTWGRFVVZsS1MyOWFTV2gyWTA1QlVVVkNRbEZCUkdkblJWQkJSRU5EUVZGdlEyZG5SVUpCU3pST0NqSXJUQzlMUWtaVVRVVlpSRnB5ZVV4U1VuZHpWMmw2ZDFWdkwwRllWRFE1VDBaUE5USTJNakZGT0VwR1dVSXdaVmRCVUVSSVJubGpSREZNV1RCalp6a0tiWGsyZDFoRFJsb3pLM0ZoZDFaaVZYQTVTSFphWVZoYVdITnlTVnBDVjNwUmVrMUNUelJqVW5WSk5tVjFXRTlQUW1SUlF6bDFOVUppTkhNclpFOHZZZ3BMYVVWVVJGSXhPWEZxV0V3eFQzRTRUV3BvVEc5WFptNVpMeTlIVVdGSkx6QnlNVGRvYkZwMFowRk1Za1ZWVjFWalZqbHBObVp1TlhCSk1XdzJOVkJUQ2sxNVkwUlFSa1YzVW5aUldGVkdRVXQzU1hoeE1EaFdNMmh5UTNBek1qSkNPV3BVWjBGaWNUbHhORnBVWkdWVWRFOTVUM05TTjBwT2NsUkJVUzk2WTNnS2MwZE1OV2hNUVdrMGVIZzJTRWN3TkU1YVFXUnpSbGhHYXpRMVFWRkRjREZtUjFwaFlpOVRSakUzYWpsWmJVdFROalZLZFM5c1ZIbHdjRUpsUkZod1VRcERNMlJwYzIxbllqQlFlVGd5Tm10T01GZE5RMEYzUlVGQllVNWFUVVpqZDBSbldVUldVakJRUVZGSUwwSkJVVVJCWjB0clRVRTRSMEV4VldSRmQwVkNDaTkzVVVaTlFVMUNRV1k0ZDBoUldVUldVakJQUWtKWlJVWkRXV3RVVVVwNlNVZFFZM0V5T1VkUGQyaElUamxtWlc5SllreE5RbFZIUVRGVlpFVlJVVThLVFVGNVEwTnRkREZaYlZaNVltMVdNRnBZVFhkRVVWbEtTMjlhU1doMlkwNUJVVVZNUWxGQlJHZG5SVUpCU0hsSFprWm5Obk5QU0VzMlptRktRVTFIWlFwT1NVeEphRUpWUlVzM2MySlBibVZDWWxGQ1ZETXZlRkJ2Tm1kVFdtbHJWVGRqVldwaFFUQTBkRzVvY0d4b01VMHdVVTF4TmtkUVZtMVlTMlIyYkV4akNsQjNOR0pTZDNGNmQzTkZXazV5VVVZeVppdFNVVlZOWkhsMWVYSmpVRXBLUVdWS2NWQjRSM2xsUTFOamVWWnNOVkZ2UjBOWFJHbDNNSGw0UVVodlMwSUtka0pSZFVsalUwaDJaMlU0V1c1WVRXTmpaR2hOUkdOcFJHUkRPVkphUkZCSVVtWnlkbEZMY2pWMFVsZHNkaXQ0UzFReVVGTklWWGhHV25sWk0zbGtRd3BYVlRWSmVVaFJkRzVhVGpNNU1YQllWVGhEYWtSYVZWTlljRXRaTHpnemNuaFJjblpzVWpCaFpVZFFVMGx5V1hCYU1GRnFjRXhvU2tSR2RVeHNjSFYzQ2k4MWVqVm5kWGhZYWpjM2NVTlBXbVpPTVVsTGVVNDFVMVZET0RkaGNXb3hkRzE2WkdSRE1VNUVkMWxUYWpGQlJuTjZRbXBKWWk5QlJXVklVMXBzVDBRS2NGSnpQUW90TFMwdExVVk9SQ0JEUlZKVVNVWkpRMEZVUlMwdExTMHRDZz09JyAtLWFwaXNlcnZlci1lbmRwb2ludCAnaHR0cHM6Ly84NzQzMDU4Qjk3QkJBNDNCRkExM0RDRDVFQ0JGODk5Ri5ncjcuYXAtc291dGgtMS5la3MuYW1hem9uYXdzLmNvbScgIC0ta3ViZWxldC1leHRyYS1hcmdzICItLW5vZGUtbGFiZWxzPW5vZGUua3ViZXJuZXRlcy5pby9saWZlY3ljbGU9c3BvdCIgJ211a3RhLXVhdCcKCiMgQWxsb3cgdXNlciBzdXBwbGllZCB1c2VyZGF0YSBjb2Rl"
  instance_market_options {
    market_type = "spot"
  }
  metadata_options {
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "disabled"
  }
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 50
      volume_type = "gp2"
      delete_on_termination = "true"
    }
  }
  network_interfaces {
    security_groups = ["sg-0716e1e66f3d095bc"]
  }
}

resource "aws_autoscaling_group" "asg" {
  depends_on = [aws_launch_template.launch_template]
  availability_zones        = ["ap-south-1b"]
  capacity_rebalance        = "false"
  default_cooldown          = "300"
  default_instance_warmup   = "0"
  desired_capacity          = "${var.number_of_worker_nodes}"
  force_delete              = "false"
  health_check_grace_period = "300"
  health_check_type         = "EC2"
  max_instance_lifetime     = "0"
  max_size                  = "${var.number_of_worker_nodes}"
  metrics_granularity       = "1Minute"
  min_size                  = "${var.number_of_worker_nodes}"
  name_prefix               = "${var.cluster_name}-spot"
  protect_from_scale_in     = "false"
  service_linked_role_arn   = "arn:aws:iam::880678429748:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
  suspended_processes       = ["AZRebalance"]

  launch_template {
    id      = aws_launch_template.launch_template.id
    version = "$Default"
  }

  tag {
    key                 = "KubernetesCluster"
    propagate_at_launch = "true"
    value               = "${var.cluster_name}"
  }

  tag {
    key                 = "Name"
    propagate_at_launch = "true"
    value               = "${var.cluster_name}-spot-eks_asg"
  }

  tag {
    key                 = "k8s.io/cluster/${var.cluster_name}"
    propagate_at_launch = "true"
    value               = "owned"
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster_name}"
    propagate_at_launch = "true"
    value               = "owned"
  }

  wait_for_capacity_timeout = "10m"
}

resource "aws_iam_role" "eks_iam" {
  name = "${var.cluster_name}-eks"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "EKSWorkerAssumeRole"
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(var.cluster_oidc_url, "https://", "")}"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${replace(var.cluster_oidc_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "custom_ebs_policy" {
  name        = "${var.cluster_name}-ebs"
  description = "Custom policy for EBS volume management"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Statement1"
        Effect = "Allow"
        Action = [
          "ec2:CreateVolume",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:CreateTags",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumeStatus",
          "ec2:ModifyVolume"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = "${aws_iam_role.eks_iam.name}"
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEC2FullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  role       = "${aws_iam_role.eks_iam.name}"
}

resource "aws_iam_role_policy_attachment" "cluster_custom_ebs" {
  policy_arn = aws_iam_policy.custom_ebs_policy.arn
  role       = "${aws_iam_role.eks_iam.name}"
}

resource "aws_iam_openid_connect_provider" "eks_oidc_provider" {
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = ["${data.tls_certificate.thumb.certificates.0.sha1_fingerprint}"] # This should be empty or provide certificate thumbprints if needed
  url            = "${var.cluster_oidc_url}" # Replace with the OIDC URL from your EKS cluster details
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name      = "${aws_eks_cluster.eks.name}"
  addon_name        = "kube-proxy"
  resolve_conflicts = "OVERWRITE"
}
resource "aws_eks_addon" "core_dns" {
  cluster_name      = "${aws_eks_cluster.eks.name}"
  addon_name        = "coredns"
  resolve_conflicts = "OVERWRITE"
}
resource "aws_eks_addon" "aws_ebs_csi_driver" {
  cluster_name      = "${aws_eks_cluster.eks.name}"
  addon_name        = "aws-ebs-csi-driver"
  resolve_conflicts = "OVERWRITE"
}