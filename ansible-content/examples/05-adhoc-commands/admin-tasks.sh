#!/bin/bash
# Ansible Administration Tasks Script
# Common administrative operations using ad hoc commands

INVENTORY="./inventory/hosts"

#=============================================
# MENU FUNCTIONS
#=============================================

show_menu() {
    echo ""
    echo "========================================="
    echo "  Ansible Administration Menu"
    echo "========================================="
    echo "1.  Check connectivity (ping)"
    echo "2.  System information"
    echo "3.  Disk usage"
    echo "4.  Memory usage"
    echo "5.  CPU load"
    echo "6.  Check running services"
    echo "7.  Install package"
    echo "8.  Remove package"
    echo "9.  Start/Stop/Restart service"
    echo "10. Create user"
    echo "11. Update all packages"
    echo "12. Reboot servers"
    echo "13. Run custom command"
    echo "0.  Exit"
    echo "========================================="
}

check_connectivity() {
    echo "Checking connectivity..."
    ansible all -i $INVENTORY -m ping
}

system_info() {
    echo "Gathering system information..."
    ansible all -i $INVENTORY -m setup -a "filter=ansible_distribution*"
    ansible all -i $INVENTORY -m shell -a "uname -a"
}

disk_usage() {
    echo "Checking disk usage..."
    ansible all -i $INVENTORY -m shell -a "df -h | head -10"
}

memory_usage() {
    echo "Checking memory usage..."
    ansible all -i $INVENTORY -m shell -a "free -m"
}

cpu_load() {
    echo "Checking CPU load..."
    ansible all -i $INVENTORY -m shell -a "uptime && cat /proc/loadavg"
}

running_services() {
    echo "Checking running services..."
    read -p "Enter service name (or 'all' for summary): " service
    if [ "$service" == "all" ]; then
        ansible all -i $INVENTORY -m shell -a "systemctl list-units --type=service --state=running | head -20" --become
    else
        ansible all -i $INVENTORY -m shell -a "systemctl status $service" --become
    fi
}

install_package() {
    read -p "Enter package name to install: " package
    read -p "Target group (default: all): " target
    target=${target:-all}
    echo "Installing $package on $target..."
    ansible $target -i $INVENTORY -m package -a "name=$package state=present" --become
}

remove_package() {
    read -p "Enter package name to remove: " package
    read -p "Target group (default: all): " target
    target=${target:-all}
    echo "Removing $package from $target..."
    ansible $target -i $INVENTORY -m package -a "name=$package state=absent" --become
}

manage_service() {
    read -p "Enter service name: " service
    read -p "Action (start/stop/restart/status): " action
    read -p "Target group (default: all): " target
    target=${target:-all}

    case $action in
        start|stop|restart)
            ansible $target -i $INVENTORY -m service -a "name=$service state=${action}ed" --become
            ;;
        status)
            ansible $target -i $INVENTORY -m shell -a "systemctl status $service" --become
            ;;
        *)
            echo "Invalid action"
            ;;
    esac
}

create_user() {
    read -p "Enter username: " username
    read -p "Enter shell (default: /bin/bash): " shell
    shell=${shell:-/bin/bash}
    read -p "Target group (default: all): " target
    target=${target:-all}
    echo "Creating user $username on $target..."
    ansible $target -i $INVENTORY -m user -a "name=$username shell=$shell state=present" --become
}

update_packages() {
    read -p "Target group (default: all): " target
    target=${target:-all}
    read -p "Are you sure you want to update all packages on $target? (yes/no): " confirm
    if [ "$confirm" == "yes" ]; then
        echo "Updating packages on $target..."
        ansible $target -i $INVENTORY -m package -a "name=* state=latest" --become
    else
        echo "Update cancelled"
    fi
}

reboot_servers() {
    read -p "Target group: " target
    read -p "Are you sure you want to reboot $target? (yes/no): " confirm
    if [ "$confirm" == "yes" ]; then
        echo "Rebooting $target..."
        ansible $target -i $INVENTORY -m reboot -a "reboot_timeout=300" --become
    else
        echo "Reboot cancelled"
    fi
}

custom_command() {
    read -p "Target group (default: all): " target
    target=${target:-all}
    read -p "Enter command: " cmd
    read -p "Use become/sudo? (yes/no): " use_become

    if [ "$use_become" == "yes" ]; then
        ansible $target -i $INVENTORY -m shell -a "$cmd" --become
    else
        ansible $target -i $INVENTORY -m shell -a "$cmd"
    fi
}

#=============================================
# MAIN LOOP
#=============================================

while true; do
    show_menu
    read -p "Select option: " choice

    case $choice in
        1)  check_connectivity ;;
        2)  system_info ;;
        3)  disk_usage ;;
        4)  memory_usage ;;
        5)  cpu_load ;;
        6)  running_services ;;
        7)  install_package ;;
        8)  remove_package ;;
        9)  manage_service ;;
        10) create_user ;;
        11) update_packages ;;
        12) reboot_servers ;;
        13) custom_command ;;
        0)  echo "Goodbye!"; exit 0 ;;
        *)  echo "Invalid option" ;;
    esac

    echo ""
    read -p "Press Enter to continue..."
done
