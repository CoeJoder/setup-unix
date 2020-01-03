#!/bin/bash
## title:           vm.sh
## description:     A remote control script for Proxmox's QEMU server, with some additional
##                  features for convenience.  Intended to be run from a WSL/Ubuntu environment on Bash.
## author:          Joe Nasca
## date:            8/13/2018
## version:         0.1
REMOTE_VIEWER="C:\Program Files\VirtViewer v6.0-256\bin\remote-viewer.exe"
VV_FILE="C:\Users\Joe\Downloads\pve_spice_connect.vv"
VNC_VIEWER="C:\Users\Joe\Downloads\vncviewer64-1.9.0.exe"
VNC_HOST="pve.local"
NODE_NAME="pve"
SSH_HOST="joe@pve.local"

shopt -s nocasematch
[[ "$#" -eq 1 ]] && \
    ([[ "$1" == "status" ]] || \
    [[ "$1" == "shutdown" ]] || \
    [[ "$1" == "stop" ]] || \
    [[ "$1" == "listvms" ]])
_oneArg=$?
[[ "$#" -eq 2 ]] && \
    ([[ "$1" == "start" ]] || \
    [[ "$1" == "shutdown" ]] || \
    [[ "$1" == "reset" ]] || \
    [[ "$1" == "suspend" ]] || \
    [[ "$1" == "resume" ]] || \
    [[ "$1" == "stop" ]] || \
    [[ "$1" == "status" ]] || \
    [[ "$1" == "vnc" ]] || \
    [[ "$1" == "spice" ]])
_twoArgs=$?
[[ "$#" -gt 2 ]] && [[ "$1" == "set" ]]
_isSet=$?
if ([[ $# -ne 0 ]] && [[ "$_oneArg" != 0 ]] && [[ "$_twoArgs" != 0 ]] && [[ "$_isSet" != 0 ]]); then
    echo -e "Basic VM controls.  Usages:" \
        "\n  # check status of all VMs" \
        "\n      vm.sh" \
        "\n  # list all VMs" \
        "\n      vm.sh listvms" \
        "\n  # run command for each VM" \
        "\n      vm.sh shutdown|stop|status" \
        "\n  # run command for the given VMs" \
        "\n      vm.sh start|shutdown|reset|suspend|resume|stop|status|vnc|spice <csv_vm_names>" \
        "\n  # set VM options" \
        "\n      vm.sh set <vmname> [OPTIONS]"
    exit 1
fi

# if no-args or single-arg "status", just run "qm list"
if [[ $# -eq 0 ]] || \
    ([[ "$_oneArg" == 0 ]] && [[ "$1" == "status" ]]); then
    ssh -n $SSH_HOST "sudo qm list"
    exit 0
fi

# create associative array, where: arr[vmname]="vmid status"
declare -A _vmMap
while read -r _name _id _status; do
    _vmMap["$_name"]="$_id $_status"
done <<< "$(ssh -n $SSH_HOST 'sudo qm list' | awk -F" " 'NR>1 {print $2" "$1" "$3}')"

# perform task according to cmdline params
if [[ "$_oneArg" == 0 ]]; then
    _command=$1
    if [[ "$_command" == listvms ]]; then
        echo ${!_vmMap[@]}
    else
        for _vmName in "${!_vmMap[@]}"; do
            read -r _vmid _status <<< ${_vmMap[$_vmName]}
            printf ${_vmName}...
            echo "$(ssh -n $SSH_HOST "sudo qm $_command $_vmid")"
        done
    fi
elif ([[ "$_twoArgs" == 0 ]] || [[ "$_isSet" == 0 ]]); then
    _command=$1
    _csvVmNames=$2
    echo $_csvVmNames | sed -n 1'p' | tr ',' '\n' | while read _vmName; do
        read -r _vmid _status <<< ${_vmMap[$_vmName]}
        if [[ -z "$_vmid" ]]; then
            echo "VM not found: $_vmName"
            continue
        fi
        if [[ "$_command" == vnc ]]; then
            _wpVncViewer="$(wslpath -u "$VNC_VIEWER")"
            if [[ ! -f "$_wpVncViewer" ]]; then
                echo "VNC Viewer not found: $VNC_VIEWER"
                continue
            fi
            _port=$(ssh -n $SSH_HOST "sudo qm config $_vmid" \
                | grep '^args:' | sed 's/.*-vnc 0\.0\.0\.0:\([0-9]*\).*/\1/')
            "${_wpVncViewer}" "${VNC_HOST}:${_port}" &
        elif [[ "$_command" == spice ]]; then
            _wpRemoteViewer="$(wslpath -u "$REMOTE_VIEWER")"
            _wpVvFile="$(wslpath -u "$VV_FILE")"
            if [[ ! -f "$_wpRemoteViewer" ]]; then
                echo "Remote Viewer not found: $REMOTE_VIEWER"
                continue
            fi
            ssh -n $SSH_HOST "sudo pvesh create /nodes/${NODE_NAME}/qemu/${_vmid}/spiceproxy --output-format json-pretty" \
                    | jq -r 'def kv: to_entries[] | "\(.key)=\(.value)"; "[virt-viewer]", kv' > "$_wpVvFile"
            if [[ ! -f "$_wpVvFile" ]]; then
                echo "Failed to create VirtViewer connection file."
                continue
            fi
            "$_wpRemoteViewer" -- "$VV_FILE" &
        elif [[ "$_isSet" == 0 ]]; then
            printf ${_vmName}...
            echo "$(ssh -n $SSH_HOST "sudo qm set $_vmid ${@:3}")"
        else
            printf ${_vmName}...
            echo "$(ssh -n $SSH_HOST "sudo qm $_command $_vmid")"
        fi
    done
    echo "Done."
fi

