#================================================================================================
# create the cluster 
#================================================================================================
# the cluster IAM role 
resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "eks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

# attach the policy to the cluster iam role
resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  # a known policy for amazon eks cluster 
}

# create the main cluster (contorl plane)
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn # connect the IAM role for it.
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids = var.private_subnet_ids # use the private subnets for the eks cluster 
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy
  ]
}

#================================================================================================
# create the Node groups (worker nodes)
#================================================================================================

# node iam role 
resource "aws_iam_role" "node" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com" # allow ec2 to assume the role
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

# attach worker node policies 
#---
resource "aws_iam_role_policy_attachment" "node_worker" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  # allow the worker node interact with EKS
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  # allow networking
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
  # allows nodes to pull container images from the ecr 
}
#---

# create the node workers 
resource "aws_eks_node_group" "this" {
  cluster_name  = aws_eks_cluster.this.name
  node_role_arn = aws_iam_role.node.arn

  subnet_ids = var.private_subnet_ids

  instance_types = [
    var.node_instance_type
  ]

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_ecr
  ]
}

#================================================================================================
# EKS OIDC (to enable IRSA)
#================================================================================================
# the EKS cluster exposes an issuer URL.
# Terraform can access it through:
# aws_eks_cluster.this.identity[0].oidc[0].issuer
# But IAM needs the issuer's TLS certificate fingerprint.
# We can retrieve it using:
data "tls_certificate" "eks" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

# create IAM OIDC provider 
resource "aws_iam_openid_connect_provider" "eks" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    data.tls_certificate.eks.certificates[0].sha1_fingerprint
  ]
}

# this will eventually enables pod --> k8s ServiceAccount --> EKS OIDC --> IAM role