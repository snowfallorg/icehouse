echo -e "
${text_bold}${text_fg_blue}icehouse${text_reset} ${text_fg_white}backup${text_reset}

${text_bold}DESCRIPTION${text_reset}

  Make a backup and push it to the drive.

${text_bold}USAGE${text_reset}

  ${text_dim}\$${text_reset} ${text_bold}icehouse backup${text_reset} [options]

${text_bold}OPTIONS${text_reset}

  --drive                             The drive to send the backup to (eg. /dev/sda)
  --pool                              The name of the ZFS pool on the drive

  --help, -h                          Show this help message
  --debug                             Show debug messages

${text_bold}EXAMPLES${text_reset}

  ${text_dim}# Create a backup on the drive /dev/sda with the ZFS pool my-pool.${text_reset}
  ${text_dim}\$${text_reset} ${text_bold}icehouse backup${text_reset} --drive ${text_underline}/dev/sda${text_reset} --pool ${text_underline}my-pool${text_underline}
"
