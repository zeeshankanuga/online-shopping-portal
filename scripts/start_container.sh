  #!/bin/bash
  set -e

  # Pull the latest Docker image from Docker Hub
  docker pull zeeshankanuga/onineshop:latest

  # Run the Docker image as a container
  docker run -d -p 5173:5173 zeeshankanuga/onineshop:latest
