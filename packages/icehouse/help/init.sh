echo -e "
${text_bold}${text_fg_blue}icehouse${text_reset} ${text_fg_white}init${text_reset}

${text_bold}DESCRIPTION${text_reset}

  Initialize a drive to use for cold storage.

${text_bold}USAGE${text_reset}

  ${text_dim}\$${text_reset} ${text_bold}icehouse init${text_reset} [options]

${text_bold}OPTIONS${text_reset}

  --drive                             The drive to initialize (eg. /dev/sda)
  --pool                              The name of the ZFS pool to create

  --help, -h                          Show this help message
  --debug                             Show debug messages

${text_bold}EXAMPLES${text_reset}

  ${text_dim}# Initialize the drive /dev/sda with a new ZFS pool named my-pool.${text_reset}
  ${text_dim}\$${text_reset} ${text_bold}icehouse init${text_reset} --drive ${text_underline}/dev/sda${text_reset} --pool ${text_underline}my-pool${text_underline}
"
