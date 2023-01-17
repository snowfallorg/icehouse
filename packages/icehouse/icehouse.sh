#!/usr/bin/env bash

#==============================#
#           Global             #
#==============================#

DEBUG=${DEBUG:-"false"}

#==============================#
#          Injected            #
#==============================#

help_root="@help@"

#==============================#
#           Logging            #
#==============================#

text_reset="\e[m"
text_bold="\e[1m"
text_dim="\e[2m"
text_italic="\e[3m"
text_underline="\e[4m"
text_blink="\e[5m"
text_highlight="\e[7m"
text_hidden="\e[8m"
text_strike="\e[9m"

text_fg_red="\e[38;5;1m"
text_fg_green="\e[38;5;2m"
text_fg_yellow="\e[38;5;3m"
text_fg_blue="\e[38;5;4m"
text_fg_magenta="\e[38;5;5m"
text_fg_cyan="\e[38;5;6m"
text_fg_white="\e[38;5;7m"
text_fg_dim="\e[38;5;8m"

text_bg_red="\e[48;5;1m"
text_bg_green="\e[48;5;2m"
text_bg_yellow="\e[48;5;3m"
text_bg_blue="\e[48;5;4m"
text_bg_magenta="\e[48;5;5m"
text_bg_cyan="\e[48;5;6m"
text_bg_white="\e[48;5;7m"
text_bg_dim="\e[48;5;8m"

# Usage: log_info <message>
log_info() {
	echo -e "${text_fg_blue}info${text_reset}  $1"
}

# Usage: log_todo <message>
log_todo() {
	echo -e "${text_bg_magenta}${text_fg_white}todo${text_reset}  $1"
}

# Usage: log_debug <message>
log_debug() {
	if [[ $DEBUG == true ]]; then
		echo -e "${text_fg_dim}debug${text_reset} $1"
	fi
}

# Usage: log_warn <message>
log_warn() {
	echo -e "${text_fg_yellow}warn${text_reset}  $1"
}

# Usage: log_error <message>
log_error() {
	echo -e "${text_fg_red}error${text_reset} $1"
}

# Usage: log_fatal <message> [exit-code]
log_fatal() {
	echo -e "${text_fg_white}${text_bg_red}fatal${text_reset} $1"

	if [ -z ${2:-} ]; then
		exit 1
	else
		exit $2
	fi
}

# Usage: clear_previous_line [number]
clear_line() {
	echo -e "\e[${1:-"1"}A\e[2K"
}

# Usage:
# 	rewrite_line <message>
# 	rewrite_line <number> <message>
rewrite_line() {
	if [[ $# == 1 ]]; then
		echo -e "\e[1A\e[2K${1}"
	else
		echo -e "\e[${1}A\e[2K${2}"
	fi
}

#==============================#
#           Options            #
#==============================#
positional_args=()

opt_help=false
opt_drive=
opt_pool=

# Usage: missing_value <option>
missing_opt_value() {
	log_fatal "Option $1 requires a value"
}

# shellcheck disable=SC2154
while [[ $# > 0 ]]; do
	case "$1" in
		-h|--help)
			opt_help=true
			shift
			;;
		--debug)
			DEBUG=true
			shift
			;;
		--drive)
			if [ -z ${2:-} ]; then
				missing_opt_value $1
			fi

			opt_drive="$2"
			shift 2
			;;
		--pool)
			if [ -z ${2:-} ]; then
				missing_opt_value $1
			fi

			opt_pool="$2"
			shift 2
			;;
		--)
			shift
			break
			;;
		-*|--*)
			echo "Unknown option $1"
			exit 1
			;;
		*)
			positional_args+=("$1")
			shift
			;;
	esac
done

passthrough_args=($@)


#==============================#
#          Helpers             #
#==============================#

# Usage: split <string> <delimiter>
split() {
	IFS=$'\n' read -d "" -ra arr <<< "${1//$2/$'\n'}"
	printf '%s\n' "${arr[@]}"
}

# Usage: lstrip <string> <pattern>
lstrip() {
	printf '%s\n' "${1##$2}"
}

# Usage: join_by <delimiter> <data> <data> [...<data>]
join_by() {
  local d=${1-} f=${2-}
  if shift 2; then
    printf %s "$f" "${@/#/$d}"
  fi
}

# Usage: show_help <path>
show_help() {
	log_debug "Showing help: ${text_bold}$1${text_reset}"
	source "${help_root}/$1.sh"
}

# Usage: privileged <command>
privileged() {
	cmd="$@"
	if command -v sudo >/dev/null; then
		log_debug "sudo $cmd"
		sudo $cmd
	elif command -v doas >/dev/null; then
		log_debug "doas $cmd"
		doas $cmd
	else
		log_warn "Could not find ${text_bold}sudo${text_reset} or ${text_bold}doas${text_reset}. Executing without privileges."
		log_debug "$cmd"
		eval "$cmd"
	fi
}

# Usage: privileged_spin <command>
privileged_spin() {
	local title=
	local cmd=()

	for arg in "$@"; do
		if [ -z "${title}" ];then
			title="${arg}"
		else
			cmd+=("${arg}")
		fi
	done

	if command -v sudo >/dev/null; then
		log_debug "sudo ${cmd[@]}"
		gum spin \
			--title "${title}" \
			--spinner.foreground="4" \
		 	-- sudo ${cmd[@]}
	elif command -v doas >/dev/null; then
		log_debug "doas ${cmd[@]}"
		gum spin \
			--title "${title}" \
			--spinner.foreground="4" \
		 	-- doas ${cmd[@]}
	else
		log_warn "Could not find ${text_bold}sudo${text_reset} or ${text_bold}doas${text_reset}. Executing without privileges."
		log_debug "${cmd[@]}"
		gum spin \
			--title "${title}" \
			--spinner.foreground="4" \
		 	-- ${cmd[@]}
	fi
}

# Usage: is_zfs_system
is_zfs_system() {
	set +e
	# Attempt to read ZFS data.
	zfs list &> /dev/null
	local zfs_exit_code=$?
	set -e

	if [ "${zfs_exit_code}" == 1 ]; then
		echo false
	else
		echo true
	fi
}

# Usage: require_zfs
require_zfs() {
	if [ "$(is_zfs_system)" != "true" ]; then
		log_fatal "ZFS failed. Make sure you have it enabled on your system."
	fi
}

# Usage: get_block_devices
get_block_devices() {
	echo $(lsblk -n -l -o name)
}

# Usage: get_active_mounts /dev/sda
get_active_mounts() {
	mount | sed -n -E "s#^${1}.+ on (.+) type .+#\\1#p"
}

#==============================#
#          Commands            #
#==============================#

icehouse_init() {
	require_zfs

	if [ "${opt_help}" == "true" ]; then
		show_help init
		exit 0
	fi

	if [ -z "${opt_drive}" ]; then
		log_fatal "No drive specified."
	fi

	if [ -z "${opt_pool}" ]; then
		log_fatal "No pool specified."
	fi

	if [[ "${opt_drive}" != /dev/* ]]; then
		log_fatal "Drive must be a path in /dev."
	fi

	log_warn "This operation will remove ${text_bold}all${text_reset} data on ${opt_drive}."
	if ! $(gum confirm "Are you sure you want to continue?" --default=No --selected.background=4 --unselected.background=8); then
		log_fatal "Initialization aborted."
	fi

	if mount | grep -q "${opt_drive}"; then
		log_warn "Device is currently mounted at the following locations:"
		mounts=$(get_active_mounts "${opt_drive}")

		for mount in $mounts; do
			log_warn "➡ ${mount}"
		done

		log_info "Would you like to unmount them?"
		if $(gum confirm "Unmount device?" --default=No --selected.background=4 --unselected.background=8); then
			for mount in $mounts; do
				privileged umount -R "${mount}"
			done
		else
			log_fatal "Device must be unmounted."
		fi
	fi

	privileged_spin "Removing existing partition tables." sgdisk --zap-all ${opt_drive}
	log_info "Removed existing partition tables."

	local luks_first_pass=true
	local luks_password=__initial__
	local luks_confirm_password=__initial_confirm__
	local luks_password_error=__initial_error__
	while [ "${luks_password_error}" != "" ]; do
		if [ "${luks_first_pass}" == "true" ]; then
			log_info "Create a password for the encrypted device."
			luks_first_pass=false
		else
			rewrite_line "$(log_error "${luks_password_error} Try again.")"
		fi

		luks_password=$(gum input --placeholder="Password" --password --prompt.foreground=4)

		rewrite_line "$(log_info "Verify the password.")"
		luks_confirm_password=$(gum input --placeholder="Password" --password --prompt.foreground=4)

		if [ "${luks_password}" != "${luks_confirm_password}" ]; then
			luks_password_error="Passwords do not match."
		elif [ "${#luks_password}" -lt 8 ]; then
			luks_password_error="Password is too short."
		else
			luks_password_error=
		fi
	done

	rewrite_line "$(log_info "Formatting with LUKS...")"
	echo -n "$luks_password" | privileged "cryptsetup luksFormat --key-file - ${opt_drive}"

	rewrite_line "$(log_info "Formatted with LUKS.")"

	local encrypted_drive="$(basename "${opt_drive}")-enc"

	log_info "Opening encrypted device ${opt_drive}..."
	echo -n "$luks_password" | privileged "cryptsetup luksOpen --key-file - ${opt_drive} ${encrypted_drive}"

	rewrite_line "$(log_info "Opened encrypted device ${encrypted_drive}.")"

	privileged_spin "Creating ZFS pool." zpool create "${opt_pool}" "${encrypted_drive}"

	log_info "Created ZFS pool ${opt_pool}."

	privileged_spin "Exporting ZFS pool." zpool export "${opt_pool}"
	log_info "Exported ZFS pool ${opt_pool}."

	log_info "Closing encrypted device ${opt_drive}..."
	privileged cryptsetup luksClose "${encrypted_drive}"

	rewrite_line "$(log_info "Closing encrypted device ${encrypted_drive}.")"

	log_info "Device successfully initialized!"
}

icehouse_backup() {
	require_zfs

	if [ "${opt_help}" == "true" ]; then
		show_help backup
		exit 0
	fi

	if [ -z "${opt_drive}" ]; then
		log_fatal "No drive specified."
	fi

	if [ -z "${opt_pool}" ]; then
		log_fatal "No pool specified."
	fi

	local encrypted_drive="$(basename "${opt_drive}")-enc"

	if privileged zfs get name -H -t filesystem "${opt_pool}" &> /dev/null; then
		log_warn "Existing pool found."
		privileged_spin "Exporting existing pool" zpool export "${opt_pool}"
	fi

	if lsblk -l -n -o name | grep -q "${encrypted_drive}"; then
		log_warn "Existing mount found."
		privileged_spin "Unmounting encrypted drive" cryptsetup luksClose "${encrypted_drive}"
	fi

	# Collect datasets before attaching the encrypted device so it doesn't show up.
	local dataset_choices=($(zfs list -H -t filesystem -o name))

	local luks_first_pass=true
	local luks_password=__initial__
	local luks_password_error=__initial_error__

	while [ "${luks_password_error}" != "" ]; do
		if [ "${luks_first_pass}" == "true" ]; then
			log_info "Enter the device's password."
			luks_first_pass=false
		else
			rewrite_line "$(log_error "${luks_password_error}")"
		fi

		luks_password=$(gum input --placeholder="Password" --password --prompt.foreground=4)

		local luksopen_output=

		if [ "${#luks_password}" -lt 8 ]; then
			luks_password_error="Password is too short."
		elif ! luksopen_output=$(echo -n "$luks_password" | privileged "cryptsetup luksOpen --key-file - ${opt_drive} ${encrypted_drive}" 2>&1); then
			luks_password_error="${luksopen_output}"
			echo echo -n "$luks_password" \| privileged "cryptsetup luksOpen --key-file - ${opt_drive} ${encrypted_drive}"
		else
			luks_password_error=
		fi
	done

	log_info "Opening encrypted device ${opt_drive}..."

	rewrite_line "$(log_info "Opened encrypted device ${encrypted_drive}.")"

	privileged_spin "Importing ZFS pool." zpool import "${opt_pool}"
	log_info "Imported ZFS pool ${opt_pool}."

	log_info "Select datasets to backup:"

	local chosen_datasets=($(gum choose \
			--no-limit \
			--height=15 \
			--cursor.foreground="4" \
			--item.foreground="7" \
			--selected.foreground="4" \
			${dataset_choices[*]} \
	))

	if [ -z "${chosen_datasets:-}" ]; then
		log_error "No datasets selected, running aborting."

		privileged_spin "Exporting ZFS pool." zpool export "${opt_pool}"
		log_info "Exported ZFS pool ${opt_pool}."

		log_info "Closing encrypted device ${opt_drive}..."
		privileged cryptsetup luksClose "${encrypted_drive}"

		rewrite_line "$(log_info "Closed encrypted device ${encrypted_drive}.")"

		log_fatal "No datasets selected."
	fi

	rewrite_line "$(log_info "Select datasets to backup: ${text_fg_blue}$(join_by ", " "${chosen_datasets[@]}")${text_reset}")"

	local storage_base="${opt_pool}/$(hostname)"

	if ! $(zfs list -H -t filesystem "${storage_base}" &> /dev/null); then
		log_debug "Creating dataset: ${storage_base}"
		privileged zfs create "${storage_base}"
	fi

	for dataset in "${chosen_datasets[@]}"; do
		log_info "Backing up dataset: ${text_fg_blue}${dataset}${text_reset}"

		local base_snapshot="${dataset}@icehouse-base"
		local generated_snapshot="${dataset}@icehouse-$(date +%Y%m%d)"

		local dataset_parts=($(split "${dataset}" "/"))
		local current_target="${storage_base}"

		local dataset_exists=true

		for dataset_part in "${dataset_parts[@]}"; do
			current_target="${current_target}/${dataset_part}"
			if ! $(zfs list -H -t filesystem "${current_target}" &> /dev/null); then
				log_debug "Creating dataset: ${current_target}"
				privileged zfs create "${current_target}"
				dataset_exists=false
			fi
		done

		if [ "${dataset_exists}" == "false" ] || ! privileged zfs get name -t snapshot "${base_snapshot}" &> /dev/null; then
			log_info "No prior snapshots detected for dataset ${dataset}."

			privileged_spin "Creating base snapshot" zfs snapshot "${base_snapshot}"

			log_info "Created snapshot: ${text_fg_blue}${base_snapshot}${text_reset}"

			log_info "Sending snapshot to device..."
			privileged zfs send "${base_snapshot}" | pv --timer --progress --eta | privileged zfs recv -Fu "${current_target}"

			rewrite_line 2 "$(log_info "Snapshot sent to device.")"
		else
			if privileged zfs get name -t snapshot "${generated_snapshot}" &> /dev/null; then
				log_info "Using existing snapshot: ${text_fg_blue}${generated_snapshot}${text_reset}"
			else
				privileged_spin "Creating snapshot" zfs snapshot "${generated_snapshot}"
				log_info "Created snapshot: ${text_fg_blue}${generated_snapshot}${text_reset}"
			fi

			local common_base="${base_snapshot}"

			local existing_snapshots=($(privileged zfs list -H -t snapshot -o name "${current_target}" | \
				sed -E "s#${current_target}@(.+)#\\1#" \
			))

			if [[ "${#existing_snapshots[@]}" == 0 ]]; then
				log_warn "Missing base snapshot: ${text_fg_red}${current_target}@icehouse-base${text_reset}."
				log_warn "Sending base snapshot to device..."
				privileged zfs send "${base_snapshot}" | pv --timer --progress --eta | privileged zfs recv -Fu "${current_target}"

				rewrite_line 2 "$(log_info "Base snapshot sent to device.")"

				log_info "Sending snapshot to device..."

				privileged zfs send -i "${common_base}" "${generated_snapshot}" | pv --timer --progress --eta | privileged zfs recv -Fu "${current_target}"

				rewrite_line 2 "$(log_info "Snapshot sent to device.")"
			else
				common_base="${dataset}@${existing_snapshots[-1]}"

				if [ "${generated_snapshot}" == "${common_base}" ]; then
					log_info "Snapshot already exists on device: ${text_fg_blue}${generated_snapshot}${text_reset}"
					exit 0
				fi

				log_info "Sending incremental snapshot to device..."

				privileged zfs send -i "${common_base}" "${generated_snapshot}" | pv --timer --progress --eta | privileged zfs recv -Fu "${current_target}"

				rewrite_line 2 "$(log_info "Snapshot sent to device.")"
			fi
		fi
	done

	privileged_spin "Exporting ZFS pool." zpool export "${opt_pool}"
	log_info "Exported ZFS pool ${opt_pool}."

	log_info "Closing encrypted device ${opt_drive}..."
	privileged cryptsetup luksClose "${encrypted_drive}"

	rewrite_line "$(log_info "Closing encrypted device ${encrypted_drive}.")"
}

#==============================#
#          Execute             #
#==============================#

if [ -z "${positional_args:-}" ]; then
	if [[ $opt_help == true ]]; then
		show_help icehouse
		exit 0
	else
		log_fatal "Called with no arguments. Run with ${text_bold}--help${text_reset} for more information."
	fi
fi

case ${positional_args[0]} in
	init)
		log_debug "Running subcommand: ${text_bold}icehouse_init${text_reset}"
		icehouse_init
		;;
	backup)
		log_debug "Running subcommand: ${text_bold}icehouse_backup${text_reset}"
		icehouse_backup
		;;
	*)
		log_fatal "Unknown subcommand: ${text_bold}${positional_args[0]}${text_reset}"
		;;
esac

