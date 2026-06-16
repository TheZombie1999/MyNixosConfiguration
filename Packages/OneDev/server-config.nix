{
  writeTextDir,
  http_host ? "0.0.0.0",
  http_port ? "6610",
  ssh_port ? "6611",
  ...
}:
writeTextDir "conf/server.properties" ''
  # Specify bind address for http service, use 0.0.0.0 to listen on all interfaces. 
  # Note that 127.0.0.1 will always be bound as OneDev needs to access localhost for 
  # some internal operations.
  http_host=${http_host}

  # Specify port for http service
  http_port=${http_port}

  # Specify port for embedded ssh server that will enable ssh based services such as 
  # git over ssh. Comment out this line to disable ssh access
  ssh_port=${ssh_port}

  # Specify name of the server displayed in cluster. Leave empty to use host name
  # server_name=

  # Specify ip address for clustering. Leave empty to detect automatically 
  # cluster_ip=

  # Specify port for clustering.
  cluster_port=5710
''
