# Commands - Online Shopping Protal

1. Cloning Repository
    ```powershell
    git clone https://github.com/zeeshankanuga/online-shopping-portal.git
    ```

2. Installing Docker and Docker Compose
    ```powershell
    chmod +x docker_installation.sh
    ./docker_installation.sh
    sudo usermod -aG docker $USER
    sudo systemctl start docker
    ```

3. Building Dockerfile
    ```powershell
    docker build -t online_store:v1 .
    docker tag -t zeeshankanuga/onineshop:latest
    docker push zeeshankanuga/onineshop:latest
    ```
4. Implementing Docker Compose
    ```powershell
    docker-compose up -d
    ```
5. Set Python virtual environment
     ```powershell
    python3 -m venv myenv
    source myenv/bin/activate
    ```
6. run python file
     ```powershell
    python agent.py
    ```   
---