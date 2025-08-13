#!/bin/bash

# Set the AWS profile to use
export AWS_PROFILE=vetpartners-uat-engineers

# List all backup vault names
BACKUP_VAULT_NAMES=$(aws backup list-backup-vaults --query 'BackupVaultList[*].BackupVaultName' --output text)

# Loop through each backup vault name
for BACKUP_VAULT_NAME in $BACKUP_VAULT_NAMES; do
  echo "Processing backup vault: $BACKUP_VAULT_NAME"

  # List all recovery point ARNs for the current backup vault
  RECOVERY_POINT_ARNS=$(aws backup list-recovery-points-by-backup-vault --backup-vault-name $BACKUP_VAULT_NAME --query 'RecoveryPoints[*].RecoveryPointArn' --output text)

  # Loop through each recovery point ARN and delete it
  for RECOVERY_POINT_ARN in $RECOVERY_POINT_ARNS; do
    echo "Deleting recovery point: $RECOVERY_POINT_ARN"
    aws backup delete-recovery-point --backup-vault-name $BACKUP_VAULT_NAME --recovery-point-arn $RECOVERY_POINT_ARN
  done
done

echo "All recovery points have been deleted from all backup vaults."