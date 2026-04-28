resource "aws_guardduty_detector" "this" {
  count = var.enable_guardduty ? 1 : 0

  enable = true

  datasources {
    s3_logs {
      # S3 protection detects threats like unusual data access patterns and
      # credential exfiltration via S3 API calls. Minimal additional cost.
      enable = true
    }

    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          # On-demand malware scanning of EBS volumes on suspicious findings.
          # Costs per GB scanned; enable per risk tolerance.
          enable = true
        }
      }
    }
  }

  tags = local.common_tags
}
