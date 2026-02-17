#!/usr/bin/env python3
"""
Custom Dynamic Inventory Script Example

This script demonstrates how to create a custom dynamic inventory.
It returns host information in JSON format.

Usage:
    ./custom_inventory.py --list    # List all groups and hosts
    ./custom_inventory.py --host <hostname>  # Get host variables

Requirements:
    - Python 3.x
    - Make script executable: chmod +x custom_inventory.py
"""

import json
import argparse
import os

def get_inventory():
    """
    Return complete inventory structure.
    In real scenarios, this would fetch from an API, database, or cloud provider.
    """

    inventory = {
        # Group definitions with hosts
        "webservers": {
            "hosts": [
                "web1.example.com",
                "web2.example.com",
                "web3.example.com"
            ],
            "vars": {
                "http_port": 80,
                "https_port": 443,
                "document_root": "/var/www/html"
            }
        },

        "dbservers": {
            "hosts": [
                "db1.example.com",
                "db2.example.com"
            ],
            "vars": {
                "db_port": 3306,
                "db_engine": "mysql"
            }
        },

        "appservers": {
            "hosts": [
                "app1.example.com",
                "app2.example.com"
            ],
            "vars": {
                "app_port": 8080
            }
        },

        "loadbalancers": {
            "hosts": [
                "lb1.example.com"
            ]
        },

        # Parent groups using children
        "production": {
            "children": [
                "webservers",
                "dbservers",
                "appservers",
                "loadbalancers"
            ],
            "vars": {
                "environment": "production",
                "ntp_server": "time.prod.example.com"
            }
        },

        # Ungrouped hosts under 'all'
        "all": {
            "vars": {
                "ansible_user": "ansible",
                "ansible_python_interpreter": "/usr/bin/python3"
            }
        },

        # Host-specific variables
        "_meta": {
            "hostvars": {
                "web1.example.com": {
                    "ansible_host": "192.168.1.101",
                    "priority": 100
                },
                "web2.example.com": {
                    "ansible_host": "192.168.1.102",
                    "priority": 50
                },
                "web3.example.com": {
                    "ansible_host": "192.168.1.103",
                    "priority": 50
                },
                "db1.example.com": {
                    "ansible_host": "192.168.1.201",
                    "db_role": "primary"
                },
                "db2.example.com": {
                    "ansible_host": "192.168.1.202",
                    "db_role": "replica"
                },
                "app1.example.com": {
                    "ansible_host": "192.168.1.151"
                },
                "app2.example.com": {
                    "ansible_host": "192.168.1.152"
                },
                "lb1.example.com": {
                    "ansible_host": "192.168.1.10",
                    "lb_algorithm": "roundrobin"
                }
            }
        }
    }

    return inventory


def get_host_vars(hostname):
    """
    Return variables for a specific host.
    """
    inventory = get_inventory()
    hostvars = inventory.get("_meta", {}).get("hostvars", {})
    return hostvars.get(hostname, {})


def main():
    """
    Main entry point for the inventory script.
    """
    parser = argparse.ArgumentParser(
        description="Custom Dynamic Inventory Script"
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="List all groups and hosts"
    )
    parser.add_argument(
        "--host",
        type=str,
        help="Get variables for a specific host"
    )

    args = parser.parse_args()

    if args.list:
        # Return complete inventory
        print(json.dumps(get_inventory(), indent=2))
    elif args.host:
        # Return host-specific variables
        print(json.dumps(get_host_vars(args.host), indent=2))
    else:
        # Default to --list behavior
        print(json.dumps(get_inventory(), indent=2))


if __name__ == "__main__":
    main()
