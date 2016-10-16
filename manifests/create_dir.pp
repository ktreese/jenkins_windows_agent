# Recursively create directories; at present, this does not set the mode so account for that elsewhere in your manifest
define jenkins_windows_agent::create_dir ($drive, $path, $spliton = '/') {
  $folders = split($path, $spliton)

  $folders.each |$index, $folder| {
    $calculated_folder = inline_template("<%= @folders[0, @index + 1].join('/') %>")
    $full_path = "${drive}${calculated_folder}"
    if (! defined(File[$full_path]) and $full_path != $drive) {
      file { $full_path :
        ensure => directory,
      }
    }
  }
}
