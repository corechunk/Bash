#!/usr/bin/env bash

# Determine the source directory based on execution context
if [ -d "bash" ]; then
    # Called from root of repo
    SCRIPT_DIR="bash"
else
    # Called from within this folder
    SCRIPT_DIR="."
fi

# User configuration directory
CONFIG_DIR="$HOME"

prompt_user() {
    local message=$1
    local response

    for(( i=0;i<2;i++ ));do
        read -p "$message [y/n]: " response
        if [[ "$response" == "y" || "$response" == "Y" ]];then
            return 0
        elif [[ "$response" == "n" || "$response" == "N" ]];then
            return 1
        fi
    done
    return 1
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
    return $?
}

str_finder(){              #           (( 1.2 ))
    if grep -q "$2" "$1";then
        return 0
    else
        return 1
    fi
}
str_finder_sudo(){              #           (( 1.2 ))
    if sudo grep -q "$2" "$1";then
        return 0
    else
        return 1
    fi
}

recopy(){
    if [[ -f "$2" ]];then
        cp "$1" "$2"
        if [ $? -eq 0 ];then echo "successfully re-copied"; fi
        return 0
    fi
    echo "file doesn't exist"
    return 1
}

# Function to install kitty-themes     (( 3 ))
copy_bash_scripts() {
    local target_script="$THEMES_DIR"/*.json
    local custom_script=("$SCRIPT_DIR/custom"/*.json)

    # Ensure variables are defined
    if [ -z "$THEMES_DIR" ] || [ -z "$SCRIPT_DIR" ]; then
        echo "Error: THEMES_DIR or SCRIPT_DIR is not set" >&2
        return 1
    fi

    # Check if source and destination directories exist
    if [ ! -d "$SCRIPT_DIR/custom" ]; then
        echo "Error: $SCRIPT_DIR/custom does not exist" >&2
        return 1
    fi
    if [ ! -d "$THEMES_DIR" ]; then
        echo "Error: $THEMES_DIR does not exist" >&2
        return 1
    fi

    # Check if any .json files exist
    if [ ${#custom_jsons[@]} -eq 0 ] || [ ! -f "${custom_jsons[0]}" ]; then
        echo "No .json files found in $SCRIPT_DIR/custom" >&2
        return 1
    fi

    # Determine copy mode: force (-f), skip (-n), or default (error on failure)
    local cp_option=""
    case "$1" in
        "force")
            cp_option="-f"
            echo "Copy mode: Force (overwrite existing files)"
            ;;
        "skip")
            cp_option="-n"
            echo "Copy mode: Skip (do not overwrite existing files)"
            ;;
        "")
            cp_option=""
            echo "Copy mode: Default (fail if file exists)"
            ;;
        *)
            echo "Error: Invalid copy mode '$1'. Use 'force' or 'skip'." >&2
            return 1
            ;;
    esac

    # Copy each .json file to THEMES_DIR
    local success=true
    for name in "${custom_jsons[@]}"; do
        local dest_file="$THEMES_DIR/$(basename "$name")"
        if [ "$cp_option" = "-n" ] && [ -f "$dest_file" ]; then
            echo "Skipped $name (already exists in $THEMES_DIR)"
            continue
        fi
        if cp $cp_option "$name" "$THEMES_DIR/"; then
            echo "Copied $name to $THEMES_DIR"
        else
            echo "Error: Failed to copy $name to $THEMES_DIR" >&2
            success=false
        fi
    done

    # Return 1 if any copy failed, 0 otherwise
    if [ "$success" = true ]; then
        return 0
    else
        return 1
    fi
}

copy_custom_script(){   #1 - name   #all problem logged
    local local_script="$SCRIPT_DIR/$1"
    local config_script="$CONFIG_DIR/$1"

    if [ ! -f "$local_script" ];then
        echo "$local_script not found to copy"
        return 1
    fi
    if [ -f "$config_script" ];then
        echo "$config_script already exists"
        if prompt_user "Do you want to re-copy $config_script?";then
            cp -fv "$local_script" "$config_script" && echo "finished re-copying" && return 0 || echo "failed to re-copy" && return 1;
        else
            echo aborting recopy;return 2;
        fi
    else
        if prompt_user "Do you want to copy $config_script?";then
            cp -v "$local_script" "$config_script" && echo "finished copying" && return 0 || echo "failed to copy" && return 1;
        else
            echo aborting copy;return 2;
        fi
    fi

}
copy_scripts_folder(){   #1 - folder name   #all problem logged
    local local_folder="$SCRIPT_DIR/$1"
    local config_folder="$CONFIG_DIR/$1"

    if [ ! -d "$local_folder" ];then
        echo "$local_folder not found to copy"
        return 1
    fi
    if [ -d "$config_folder" ];then
        echo "$config_folder already exists"
        if prompt_user "Do you want to re-copy $config_folder?";then
            cp -rfv "$local_folder" "$CONFIG_DIR/" && echo "finished re-copying" && return 0 || echo "failed to re-copy" && return 1;
        else
            echo aborting recopy;return 2;
        fi
    else
        if prompt_user "Do you want to copy $config_folder?";then
            cp -rv "$local_folder" "$CONFIG_DIR/" && echo "finished copying" && return 0 || echo "failed to copy" && return 1;
        else
            echo aborting copy;return 2;
        fi
    fi

}

include_custom_str(){  # $1 file_name ".bashrc"  $2 str "source ~/.bashrc_custom"
    local target_file="$CONFIG_DIR/$1"
    local str="$2"

    if [ ! -f "$target_file" ];then echo "$target_file doesn't exist !!";return 1;fi

    if str_finder "$target_file" "$str";then
        echo "already included";return 2;
    else
        echo "$str" >> "$target_file" && echo "included successfilly" && return 0 || echo "failed to include !!" && return 1
    fi

}
include_custom_str_sudo(){  # $1 file_name ".bashrc"  $2 str "source ~/.bashrc_custom"
    local target_file="$1"
    local str="$2"

    if [ ! -f "$target_file" ];then echo "$target_file doesn't exist !!";return 1;fi

    if str_finder_sudo "$target_file" "$str";then
        echo "already included";return 2;
    else
        echo "$str" | sudo tee -a "$target_file" && echo "included successfilly" && return 0 || echo "failed to include !!" && return 1
    fi

}


# calling functions
copy_scripts_folder ".scripts_102"
copy_custom_script ".bashrc_custom"
include_custom_str ".bashrc" "source \"$HOME/.bashrc_custom\""
#include_custom_str ".profile" "source \"$HOME/.scripts_102/startup\""

if prompt_user "warning --> wanna make 'mkdir,chown,mount,unmount' work without password ?";then
    include_custom_str_sudo "/etc/sudoers" "netchunk ALL=(ALL) NOPASSWD: /bin/mkdir"
    include_custom_str_sudo "/etc/sudoers" "netchunk ALL=(ALL) NOPASSWD: /bin/chown"
    include_custom_str_sudo "/etc/sudoers" "netchunk ALL=(ALL) NOPASSWD: /bin/mount"
    include_custom_str_sudo "/etc/sudoers" "netchunk ALL=(ALL) NOPASSWD: /bin/umount"
fi