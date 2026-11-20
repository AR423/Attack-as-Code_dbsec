#!/usr/bin/env python3
"""
Checks the IAM role attached to an RDS instance for over-permissive
policies (e.g. AdministratorAccess, or wildcard Action/Resource inline policies).
Usage: python iam_abuse_check.py <role-name> [--profile PROFILE] [--region REGION]
"""
import argparse
import json
import boto3

DANGEROUS_MANAGED_POLICIES = {
    "arn:aws:iam::aws:policy/AdministratorAccess",
    "arn:aws:iam::aws:policy/PowerUserAccess",
    "arn:aws:iam::aws:policy/IAMFullAccess",
}

def check_wildcard(policy_doc):
    findings = []
    statements = policy_doc.get("Statement", [])
    if isinstance(statements, dict):
        statements = [statements]
    for stmt in statements:
        if stmt.get("Effect") != "Allow":
            continue
        actions = stmt.get("Action", [])
        resources = stmt.get("Resource", [])
        if isinstance(actions, str):
            actions = [actions]
        if isinstance(resources, str):
            resources = [resources]
        if "*" in actions and "*" in resources:
            findings.append("Inline policy allows Action:* on Resource:* (full admin via inline policy)")
    return findings

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("role_name")
    parser.add_argument("--profile", default="terraform-deployer")
    parser.add_argument("--region", default="us-east-2")
    args = parser.parse_args()

    session = boto3.Session(profile_name=args.profile, region_name=args.region)
    iam = session.client("iam")

    print(f"=== IAM Permission Abuse Check for role: {args.role_name} ===")

    findings = []

    attached = iam.list_attached_role_policies(RoleName=args.role_name)["AttachedPolicies"]
    for policy in attached:
        print(f"Attached managed policy: {policy['PolicyName']} ({policy['PolicyArn']})")
        if policy["PolicyArn"] in DANGEROUS_MANAGED_POLICIES:
            findings.append(f"Over-permissive managed policy attached: {policy['PolicyArn']}")

    inline_names = iam.list_role_policies(RoleName=args.role_name)["PolicyNames"]
    for name in inline_names:
        doc = iam.get_role_policy(RoleName=args.role_name, PolicyName=name)["PolicyDocument"]
        print(f"Inline policy '{name}': {json.dumps(doc)}")
        findings.extend(check_wildcard(doc))

    print()
    if findings:
        for f in findings:
            print(f"FINDING: {f}")
    else:
        print("No over-permissive IAM configuration found.")

if __name__ == "__main__":
    main()