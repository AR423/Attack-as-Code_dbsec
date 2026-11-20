#!/usr/bin/env python3
"""
Checks whether any RDS snapshots of the target DB instance are
publicly shared (restore attribute includes 'all').
Usage: python snapshot_exposure_check.py <db-instance-identifier> [--profile PROFILE] [--region REGION]
"""
import sys
import argparse
import boto3

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("db_instance_identifier")
    parser.add_argument("--profile", default="terraform-deployer")
    parser.add_argument("--region", default="us-east-2")
    args = parser.parse_args()

    session = boto3.Session(profile_name=args.profile, region_name=args.region)
    rds = session.client("rds")

    print(f"=== Snapshot Exposure Check for {args.db_instance_identifier} ===")

    snapshots = rds.describe_db_snapshots(
        DBInstanceIdentifier=args.db_instance_identifier
    )["DBSnapshots"]

    if not snapshots:
        print("No snapshots found for this instance.")
        return

    findings = []
    for snap in snapshots:
        snap_id = snap["DBSnapshotIdentifier"]
        attrs = rds.describe_db_snapshot_attributes(
            DBSnapshotIdentifier=snap_id
        )["DBSnapshotAttributesResult"]["DBSnapshotAttributes"]

        for attr in attrs:
            if attr["AttributeName"] == "restore" and "all" in attr["AttributeValues"]:
                findings.append(snap_id)
                print(f"FINDING: Snapshot {snap_id} is PUBLICLY RESTORABLE (shared with 'all').")

    if not findings:
        print("No publicly shared snapshots found.")

if __name__ == "__main__":
    main()