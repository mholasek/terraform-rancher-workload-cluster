provider "rancher2" {
  api_url   = local.rancher_api_url
  token_key = local.rancher_token_key
}

resource "rancher2_cluster" "cluster" {
  name        = local.name
  description = local.cluster_description

  rke_config {
    kubernetes_version = local.kubernetes_version
    cloud_provider {
      name = local.cloud_provider_name
    }
    services {
      kubelet {
        extra_args = local.kubelet_extra_args
      }
      kube_api {
        extra_args = local.kube_api_extra_args
      }
      kube_controller {
        extra_args = local.kube_controller_extra_args
      }
      scheduler {
        extra_args = local.scheduler_extra_args
      }
      etcd {
        backup_config {
          enabled        = true
          interval_hours = 6
          retention      = 21

          s3_backup_config {
            access_key  = aws_iam_access_key.etcd_backup_user.id
            bucket_name = aws_s3_bucket.etcd_backups.id
            endpoint    = "s3.${aws_s3_bucket.etcd_backups.region}.amazonaws.com"
            region      = aws_s3_bucket.etcd_backups.region
            secret_key  = aws_iam_access_key.etcd_backup_user.secret
            folder      = "${local.name}-etcd-backup"
          }
        }
      }
    }
  }


  depends_on = [aws_s3_bucket.etcd_backups]
}

resource "rancher2_cluster_sync" "cluster" {
  cluster_id = rancher2_cluster.cluster.id
}

resource "rancher2_cluster_role_template_binding" "deploy" {
  count            = local.deploy_user_enabled
  name             = "deploy"
  role_template_id = "cluster-owner"
  cluster_id       = rancher2_cluster_sync.cluster.id
  user_id          = local.rancher_deploy_user
}
