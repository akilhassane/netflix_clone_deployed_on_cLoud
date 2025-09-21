<div align="center">
  <img src="./public/assets/DevSecOps.png" alt="Logo" width="100%" height="100%">

  <br>
  <a href="http://netflix-clone-with-tmdb-using-react-mui.vercel.app/">
    <img src="./public/assets/netflix-logo.png" alt="Logo" width="100" height="32">
  </a>
</div>

<br />

<div align="center">
  <img src="./public/assets/home-page.png" alt="Logo" width="100%" height="100%">
  <p align="center">Home Page</p>
</div>

The Project was created by N4si, you can find it here https://github.com/N4si/DevSecOps-Project 

I followed his instructions using this youtube video https://www.youtube.com/watch?v=g8X5AoqCJHc&t=150s&ab_channel=CloudChamp

And updated it along the way to fix some compatibility issues

# Deploy Netflix Clone on Cloud using Jenkins - DevSecOps Project!

### **Phase 1: Initial Setup and Deployment**

**Step 1: Launch EC2 (Ubuntu 22.04):**

- Provision an EC2 instance on AWS with Ubuntu 22.04.
- Connect to the instance using SSH.

**Step 2: Clone the Code:**

- Update all the packages and then clone the code.
- Clone your application's code repository onto the EC2 instance:
    
    ```bash
    git clone https://github.com/akilhassane/netflix_clone_deployed_on_cLoud.git
    ```
    

**Step 3: Install Docker and Run the App Using a Container:**

- Set up Docker on the EC2 instance:
    
    ```bash
    
    sudo apt-get update
    sudo apt-get install docker.io -y
    sudo usermod -aG docker $USER  # Replace with your system's username, e.g., 'ubuntu'
    newgrp docker
    sudo chmod 777 /var/run/docker.sock
    ```
    
- Build and run your application using Docker containers:
    
    ```bash
    docker build -t netflix .
    docker run -d --name netflix -p 8081:80 netflix:latest
    
    #to delete
    docker stop <containerid>
    docker rmi -f netflix
    ```

It will show an error cause you need API key

**Step 4: Get the API Key:**

- Open a web browser and navigate to TMDB (The Movie Database) website.
- Click on "Login" and create an account.
- Once logged in, go to your profile and select "Settings."
- Click on "API" from the left-side panel.
- Create a new API key by clicking "Create" and accepting the terms and conditions.
- Provide the required basic details and click "Submit."
- You will receive your TMDB API key.

### Secure Docker Build (Recommended)

Create a secret file with your TMDB API key:
```bash
echo "<your-tmdb-api-key>" > tmdb_api_key.txt
```

Build the Docker image using secrets (more secure):
```bash
DOCKER_BUILDKIT=1 docker build --secret id=tmdb_api_key,src=tmdb_api_key.txt -t netflix .
```

Clean up the secret file:
```bash
rm tmdb_api_key.txt
```

### Legacy Docker Build (Less Secure - Not Recommended)

**⚠️ WARNING:** This method exposes your API key in the Docker image and build history.

```bash
docker build --build-arg TMDB_V3_API_KEY=<your-api-key> -t netflix .
```

**Phase 2: Security**

1. **Install SonarQube and Trivy:**
    - Install SonarQube and Trivy on the EC2 instance to scan for vulnerabilities.
        
        sonarqube
        ```
        docker run -d --name sonar -p 9000:9000 sonarqube:lts-community
        ```
        
        
        To access: 
        
        publicIP:9000 (by default username & password is admin)
        
        To install Trivy:
        ```
        sudo apt-get install wget apt-transport-https gnupg lsb-release
        wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
        echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
        sudo apt-get update
        sudo apt-get install trivy        
        ```
        
        to scan image using trivy
        ```
        trivy image <imageid>
        ```
        
        
2. **Integrate SonarQube and Configure:**
    - Integrate SonarQube with your CI/CD pipeline.
    - Configure SonarQube to analyze code for quality and security issues.

**Phase 3: CI/CD Setup**

1. **Install Jenkins for Automation:**
    - Install Jenkins on the EC2 instance to automate deployment:
    Install Java
    
    ```bash
    sudo apt update
    sudo apt install fontconfig openjdk-17-jre
    java -version
    openjdk version "17.0.8" 2023-07-18
    OpenJDK Runtime Environment (build 17.0.8+7-Debian-1deb12u1)
    OpenJDK 64-Bit Server VM (build 17.0.8+7-Debian-1deb12u1, mixed mode, sharing)
    
    #jenkins
    sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
    https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt-get update
    sudo apt-get install jenkins
    sudo systemctl start jenkins
    sudo systemctl enable jenkins
    ```
    
    - Access Jenkins in a web browser using the public IP of your EC2 instance.
        
        publicIp:8080
        
2. **Install Necessary Plugins in Jenkins:**

Goto Manage Jenkins →Plugins → Available Plugins →

Install below plugins

1 Eclipse Temurin Installer (Install without restart)

2 SonarQube Scanner (Install without restart)

3 NodeJs Plugin (Install Without restart)

4 Email Extension Plugin

### **Configure Java and Nodejs in Global Tool Configuration**

Goto Manage Jenkins → Tools → Install JDK(17) and NodeJs(16)→ Click on Apply and Save


### SonarQube

Create the token

Goto Jenkins Dashboard → Manage Jenkins → Credentials → Add Secret Text. It should look like this

After adding sonar token

Click on Apply and Save

**The Configure System option** is used in Jenkins to configure different server

**Global Tool Configuration** is used to configure different tools that we install using Plugins

We will install a sonar scanner in the tools.

Create a Jenkins webhook

1. **Configure CI/CD Pipeline in Jenkins:**
- Create a CI/CD pipeline in Jenkins to automate your application deployment.

```groovy
pipeline {
    agent any
    tools {
        jdk 'jdk17'
        nodejs 'node16'
    }
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
    }
    stages {
        stage('clean workspace') {
            steps {
                cleanWs()
            }
        }
        stage('Checkout from Git') {
            steps {
                git branch: 'main', url: 'https://github.com/akilhassane/netflix_clone_deployed_on_cLoud.git'
            }
        }
        stage("Sonarqube Analysis") {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh '''$SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=netflix \
                    -Dsonar.projectKey=netflix'''
                }
            }
        }
        stage("quality gate") {
            steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'sonar-token'
                }
            }
        }
        stage('Install Dependencies') {
            steps {
                sh "npm install"
            }
        }
    }
}
```

Certainly, here are the instructions without step numbers:

**Install Dependency-Check and Docker Tools in Jenkins**

**Install Dependency-Check Plugin:**

- Go to "Dashboard" in your Jenkins web interface.
- Navigate to "Manage Jenkins" → "Manage Plugins."
- Click on the "Available" tab and search for "OWASP Dependency-Check."
- Check the checkbox for "OWASP Dependency-Check" and click on the "Install without restart" button.

**Configure Dependency-Check Tool:**

- After installing the Dependency-Check plugin, you need to configure the tool.
- Go to "Dashboard" → "Manage Jenkins" → "Global Tool Configuration."
- Find the section for "OWASP Dependency-Check."
- Add the tool's name, e.g., "DP-Check."
- Save your settings.

**Install Docker Tools and Docker Plugins:**

- Go to "Dashboard" in your Jenkins web interface.
- Navigate to "Manage Jenkins" → "Manage Plugins."
- Click on the "Available" tab and search for "Docker."
- Check the following Docker-related plugins:
  - Docker
  - Docker Commons
  - Docker Pipeline
  - Docker API
  - docker-build-step
- Click on the "Install without restart" button to install these plugins.

**Add DockerHub Credentials:**

- To securely handle DockerHub credentials in your Jenkins pipeline, follow these steps:
  - Go to "Dashboard" → "Manage Jenkins" → "Manage Credentials."
  - Click on "System" and then "Global credentials (unrestricted)."
  - Click on "Add Credentials" on the left side.
  - Choose "Secret text" as the kind of credentials.
  - Enter your DockerHub credentials (Username and Password) and give the credentials an ID (e.g., "docker").
  - Click "OK" to save your DockerHub credentials.

Now, you have installed the Dependency-Check plugin, configured the tool, and added Docker-related plugins along with your DockerHub credentials in Jenkins. You can now proceed with configuring your Jenkins pipeline to include these tools and credentials in your CI/CD process.

```groovy






pipeline{
    agent any
    tools{
        jdk 'jdk17'
        nodejs 'node16'
    }
    environment {
        SCANNER_HOME=tool 'sonar-scanner'
    }
    stages {
        stage('clean workspace'){
            steps{
                cleanWs()
            }
        }
        stage('Checkout from Git'){
            steps{
                git branch: 'main', url: 'https://github.com/akilhassane/netflix_clone_deployed_on_cLoud.git'
            }
        }
        stage("Sonarqube Analysis "){
            steps{
                withSonarQubeEnv('sonar-server') {
                    sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=netflix \
                    -Dsonar.projectKey=netflix '''
                }
            }
        }
        stage("quality gate"){
           steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'sonar-token' 
                }
            } 
        }
        stage('Install Dependencies') {
            steps {
                sh "npm install"
            }
        }
        stage('OWASP FS SCAN') {
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }
        stage('TRIVY FS SCAN') {
            steps {
                sh "trivy fs . > trivyfs.txt"
            }
        }
        stage("Docker Build & Push"){
            steps{
                script{
                   withDockerRegistry(credentialsId: 'docker', toolName: 'docker'){
                       // Use --secret with process substitution (works with Snap Docker)
                       sh """
                           tar -czf - . | sudo bash -c 'DOCKER_BUILDKIT=1 docker build --secret id=tmdb_api_key,src=<(echo "99eec89d2dc36d0cfdacb8033e3e710c") -t netflix -'
                       """
                       sh "sudo docker tag netflix akilhassane/netflix:latest "
                       sh "sudo docker push akilhassane/netflix:latest "
                    }
                }
            }
        }
        stage("TRIVY"){
            steps{
                sh "trivy image akilhassane/netflix:latest > trivyimage.txt" 
            }
        }
        stage('Deploy to container'){
            steps{
                sh 'sudo docker run -d -p 8081:80 akilhassane/netflix:latest'
            }
        }
    }
    post {
     always {
        emailext attachLog: true,
            subject: "'${currentBuild.result}'",
            body: "Project: ${env.JOB_NAME}<br/>" +
                "Build Number: ${env.BUILD_NUMBER}<br/>" +
                "URL: ${env.BUILD_URL}<br/>",
            to: 'akilhassane5@gmail.com',
            attachmentsPattern: 'trivyfs.txt,trivyimage.txt'
      }
      cleanup {
        cleanWs()
      }
    }
}

```

**For Debugging: run this in your ubuntu/linux**

If you get docker login failed error:

```bash
sudo su
sudo groupadd docker
sudo usermod -a -G docker jenkins
sudo systemctl restart jenkins

```

If you get files other than /home need more configuration error:

```bash
sudo mkdir -p /home/jenkins   # Create target directory if needed
sudo mount --bind /var/lib/jenkins /home/jenkins
```

If it asks for password:

   ```bash
   sudo visudo
   ```
       
   add this to the visudo file under the sudo members part:
     
   ```bash
   # Members of the admin group may execute without a password
   jenkins ALL=(ALL) NOPASSWD:ALL
   ```
If You need to remove some files to turn on the nodes (you can chack this by going for: Manage Jenkins -> Nodes -> Name of the Node), you can execute these commands in your ec2 instance:

  ```bash
  rm -rf /var/lib/jenkins/workspace/*
  rm -rf /var/lib/jenkins/.npm/*
  rm -rf /var/lib/jenkins/.cache/*
  rm -rf /var/lib/jenkins/.sonar/*
  rm -rf /var/lib/jenkins/tools/*
  systemctl restart jenkins
  ```

If SonarQube fails to analize your project, you can restart it by executing this command in your ec2 instance:

  ```bash
  docker restart sonar
  ```

If you want to remove unused docker containers whitch are taking too much space (use this only if you want to build the pipeline and jenkins is showing an error or if you realy need to because it will detete all of the images that where stoped but not removed):

  ```bash
  sudo docker system prune -a -f
  ```

**Phase 4: Monitoring**

1. **Install Prometheus and Grafana:**

   Set up Prometheus and Grafana to monitor your application.

   **Installing Prometheus:**

   First, create a dedicated Linux user for Prometheus and download Prometheus:

   ```bash
   sudo useradd --system --no-create-home --shell /bin/false prometheus
   wget https://github.com/prometheus/prometheus/releases/download/v2.47.1/prometheus-2.47.1.linux-amd64.tar.gz
   ```

   Extract Prometheus files, move them, and create directories:

   ```bash
   tar -xvf prometheus-2.47.1.linux-amd64.tar.gz
   cd prometheus-2.47.1.linux-amd64/
   sudo mkdir -p /data /etc/prometheus
   sudo mv prometheus promtool /usr/local/bin/
   sudo mv consoles/ console_libraries/ /etc/prometheus/
   sudo mv prometheus.yml /etc/prometheus/prometheus.yml
   ```

   Set ownership for directories:

   ```bash
   sudo chown -R prometheus:prometheus /etc/prometheus/ /data/
   ```

   Create a systemd unit configuration file for Prometheus:

   ```bash
   sudo nano /etc/systemd/system/prometheus.service
   ```

   Add the following content to the `prometheus.service` file:

   ```plaintext
   [Unit]
   Description=Prometheus
   Wants=network-online.target
   After=network-online.target

   StartLimitIntervalSec=500
   StartLimitBurst=5

   [Service]
   User=prometheus
   Group=prometheus
   Type=simple
   Restart=on-failure
   RestartSec=5s
   ExecStart=/usr/local/bin/prometheus \
     --config.file=/etc/prometheus/prometheus.yml \
     --storage.tsdb.path=/data \
     --web.console.templates=/etc/prometheus/consoles \
     --web.console.libraries=/etc/prometheus/console_libraries \
     --web.listen-address=0.0.0.0:9090 \
     --web.enable-lifecycle

   [Install]
   WantedBy=multi-user.target
   ```

   Here's a brief explanation of the key parts in this `prometheus.service` file:

   - `User` and `Group` specify the Linux user and group under which Prometheus will run.

   - `ExecStart` is where you specify the Prometheus binary path, the location of the configuration file (`prometheus.yml`), the storage directory, and other settings.

   - `web.listen-address` configures Prometheus to listen on all network interfaces on port 9090.

   - `web.enable-lifecycle` allows for management of Prometheus through API calls.

   Enable and start Prometheus:

   ```bash
   sudo systemctl enable prometheus
   sudo systemctl start prometheus
   ```

   Verify Prometheus's status:

   ```bash
   sudo systemctl status prometheus
   ```

   You can access Prometheus in a web browser using your server's IP and port 9090:

   `http://<your-server-ip>:9090`

   **Installing Node Exporter:**

   Create a system user for Node Exporter and download Node Exporter:

   ```bash
   sudo useradd --system --no-create-home --shell /bin/false node_exporter
   wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
   ```

   Extract Node Exporter files, move the binary, and clean up:

   ```bash
   tar -xvf node_exporter-1.6.1.linux-amd64.tar.gz
   sudo mv node_exporter-1.6.1.linux-amd64/node_exporter /usr/local/bin/
   rm -rf node_exporter*
   ```

   Create a systemd unit configuration file for Node Exporter:

   ```bash
   sudo nano /etc/systemd/system/node_exporter.service
   ```

   Add the following content to the `node_exporter.service` file:

   ```plaintext
   [Unit]
   Description=Node Exporter
   Wants=network-online.target
   After=network-online.target

   StartLimitIntervalSec=500
   StartLimitBurst=5

   [Service]
   User=node_exporter
   Group=node_exporter
   Type=simple
   Restart=on-failure
   RestartSec=5s
   ExecStart=/usr/local/bin/node_exporter --collector.logind

   [Install]
   WantedBy=multi-user.target
   ```

   Replace `--collector.logind` with any additional flags as needed.

   Enable and start Node Exporter:

   ```bash
   sudo systemctl enable node_exporter
   sudo systemctl start node_exporter
   ```

   Verify the Node Exporter's status:

   ```bash
   sudo systemctl status node_exporter
   ```

   You can access Node Exporter metrics in Prometheus.

2. **Configure Prometheus Plugin Integration:**

   Integrate Jenkins with Prometheus to monitor the CI/CD pipeline.

   **Prometheus Configuration:**

   To configure Prometheus to scrape metrics from Node Exporter and Jenkins, you need to modify the `prometheus.yml` file.

   Here is an example of the command to navigate to it:

   ```bash
   cd /etc/prometheus
   nano prometheus.yml
   ```

   Here is an example `prometheus.yml` configuration for your setup:

   ```yaml
   global:
     scrape_interval: 15s

   scrape_configs:
     - job_name: 'node_exporter'
       static_configs:
         - targets: ['localhost:9100']

     - job_name: 'jenkins'
       metrics_path: '/prometheus'
       static_configs:
         - targets: ['<your-jenkins-ip>:<your-jenkins-port>']
   ```

   Make sure to replace `<your-jenkins-ip>` and `<your-jenkins-port>` with the appropriate values for your Jenkins setup.

   Check the validity of the configuration file:

   ```bash
   promtool check config /etc/prometheus/prometheus.yml
   ```

   Reload the Prometheus configuration without restarting:

   ```bash
   curl -X POST http://localhost:9090/-/reload
   ```

   You can access Prometheus targets at:

   `http://<your-prometheus-ip>:9090/targets`


####Grafana

**Install Grafana on Ubuntu 22.04 and Set it up to Work with Prometheus**

**Step 1: Install Dependencies:**

First, ensure that all necessary dependencies are installed:

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https software-properties-common
```

**Step 2: Add the GPG Key:**

Add the GPG key for Grafana:

```bash
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
```

**Step 3: Add Grafana Repository:**

Add the repository for Grafana stable releases:

```bash
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
```

**Step 4: Update and Install Grafana:**

Update the package list and install Grafana:

```bash
sudo apt-get update
sudo apt-get -y install grafana
```

**Step 5: Enable and Start Grafana Service:**

To automatically start Grafana after a reboot, enable the service:

```bash
sudo systemctl enable grafana-server
```

Then, start Grafana:

```bash
sudo systemctl start grafana-server
```

**Step 6: Check Grafana Status:**

Verify the status of the Grafana service to ensure it's running correctly:

```bash
sudo systemctl status grafana-server
```

**Step 7: Access Grafana Web Interface:**

Open a web browser and navigate to Grafana using your server's IP address. The default port for Grafana is 3000. For example:

`http://<your-server-ip>:3000`

You'll be prompted to log in to Grafana. The default username is "admin," and the default password is also "admin."

**Step 8: Change the Default Password:**

When you log in for the first time, Grafana will prompt you to change the default password for security reasons. Follow the prompts to set a new password.

**Step 9: Add Prometheus Data Source:**

To visualize metrics, you need to add a data source. Follow these steps:

- Click on the gear icon (⚙️) in the left sidebar to open the "Configuration" menu.

- Select "Data Sources."

- Click on the "Add data source" button.

- Choose "Prometheus" as the data source type.

- In the "HTTP" section:
  - Set the "URL" to `http://localhost:9090` (assuming Prometheus is running on the same server).
  - Click the "Save & Test" button to ensure the data source is working.

**Step 10: Import a Dashboard:**

To make it easier to view metrics, you can import a pre-configured dashboard. Follow these steps:

- Click on the "+" (plus) icon in the left sidebar to open the "Create" menu.

- Select "Dashboard."

- Click on the "Import" dashboard option.

- Enter the dashboard code you want to import (e.g., code 1860).

- Click the "Load" button.

- Select the data source you added (Prometheus) from the dropdown.

- Click on the "Import" button.

You should now have a Grafana dashboard set up to visualize metrics from Prometheus.

Grafana is a powerful tool for creating visualizations and dashboards, and you can further customize it to suit your specific monitoring needs.

That's it! You've successfully installed and set up Grafana to work with Prometheus for monitoring and visualization.

2. **Configure Prometheus Plugin Integration:**
    - Integrate Jenkins with Prometheus to monitor the CI/CD pipeline.


**Phase 5: Notification**

1. **Implement Notification Services:**
    - Set up email notifications in Jenkins or other notification mechanisms.

# Phase 6: Kubernetes

## Create Kubernetes Cluster with Nodegroups

In this phase, you'll set up a Kubernetes cluster with node groups. This will provide a scalable environment to deploy and manage your applications.

If you need to download the AWS CLI you can use this command to do so:

```bash
# Update package index
sudo apt update

# Install required dependencies
sudo apt install -y curl unzip

# Download AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Unzip the installer
unzip awscliv2.zip

# Run the installer
sudo ./aws/install

# Clean up installation files
rm -rf awscliv2.zip aws/

# Verify installation
aws --version
```

if you need to install kubectl you can do it using this command:

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
```

## Monitor Kubernetes with Prometheus

Prometheus is a powerful monitoring and alerting toolkit, and you'll use it to monitor your Kubernetes cluster. Additionally, you'll install the node exporter using Helm to collect metrics from your cluster nodes.

### Install Node Exporter using Helm

To begin monitoring your Kubernetes cluster, you'll install the Prometheus Node Exporter. This component allows you to collect system-level metrics from your cluster nodes. Here are the steps to install the Node Exporter using Helm:

1. Add the Prometheus Community Helm repository:

    ```bash
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    ```

    If you need to firstly install helm use this command:
    ```bash
    sudo apt-get install curl gpg apt-transport-https --yes
    curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
    sudo apt-get update
    sudo apt-get install helm
    ```

3. Create a Kubernetes namespace for the Node Exporter:

    ```bash
    kubectl create namespace prometheus-node-exporter
    ```

    If you need to firstly configure AWS console do this:

    ```
    1. Access the AWS Console
    Log in to the AWS Management Console with your user account.
    
    Make sure you have permission to view or create AWS IAM access keys.

    2. Create an IAM user

    Go to: AWS Console → IAM → Users → Create user → User name: <your-username> (e.g. akil) → Next → (optional) Attach permissions now for admin workflows: choose a group or attach an admin policy if organizationally allowed →  Create user.
    
    After user creation: IAM → Users → <your-username> → Security credentials → Create access key → Download .csv (Access key ID and Secret) and store securely; the secret is shown only once.
    
    3. Navigate to IAM User Security Credentials
    In the AWS Console, go to Services > IAM (Identity and Access Management).
    
    Select Users from the sidebar.
    
    Click on your username to open the user details.
    
    Go to the Security credentials tab.
    
    4. Get (or Create) Access Keys
    If you see an existing pair of Access Key ID and Secret Access Key you can use, note them down securely.
    
    If none exist or you want a new set, click Create access key.
    
    Download the generated credentials immediately. The Secret Access Key is only visible at creation time.
    
    5. Find Your AWS Region
    In the top-right of the AWS Console, you will see your region (e.g., us-east-1, eu-west-1).
    
    Confirm the region where your infrastructure (EKS, EC2, etc.) is deployed.
    
    Copy this region string.
    
    6. Decide Output Format
    The AWS CLI supports several output formats:
    
    json – (recommended; the default if you just hit enter)
    
    text – for plain text output
    
    table – for a more readable table view
    
    7. Run aws configure on Your Terminal
    Open a terminal, then execute the command:
    
    aws configure
    
    Enter each piece of information when prompted:
    
    AWS Access Key ID: Enter the value from step 4.
    
    AWS Secret Access Key: Enter the value from step 4.
    
    Default region name: Enter the value from step 5.
    
    Default output format: Choose one from step 6, or hit Enter for JSON.

    8. Create the EKS cluster IAM role

    Go to: IAM → Roles → Create role → Trusted entity: AWS service → Use cases: EKS → EKS – Cluster → Next → Attach policy AmazonEKSClusterPolicy → Next → Role name: <your-pick> (e.g. EKSClusterRole) → Create role.
    
    9. Create the EKS cluster (Console)

    Go to: EKS → Add cluster → Create → Name: <your-pick> (e.g netflix) → Kubernetes version: leave default latest → Cluster service role: <role-you-created> (e.g. EKSClusterRole) → VPC: select a VPC that has at least two subnets in different AZs → Subnets: choose two or more (prefer private for nodes) → Cluster endpoint access: Public and private (simple start) → Create and wait until Status = Active.

    10. Add a managed node group

    Go to: EKS → Clusters → netflix → Compute tab → Add node group → Name: ng-1 → Node IAM role: EKSNodeRole → AMI family: Amazon Linux 2 → Instance type: t3.medium (example) → Desired size: 2 (min 1, max 3) → Subnets: select private subnets from the same VPC → Create and wait until Active.
    
    Managed node groups simplify lifecycle management of worker nodes for the cluster.
    
    11. Grant admin access to the IAM user via Access Entries
    
    Go to: EKS → Clusters → <your-cluster-name> (e.g. netflix) → Access tab → Create access entry → IAM principal: <your-arn> (e.g. arn:aws:iam::<your-account-id>:user/akil) → Type: Standard → Username: akil → Groups: system:masters → Next → Add access policy → Policy: AmazonEKSClusterAdminPolicy → Access scope: Cluster → Create.
    
    Access Entries are the modern, console-managed way to authorize IAM principals for Kubernetes RBAC without editing aws-auth manually.

    12. In your EC2 instance make sure to execute these commands:

    Command 1:

    aws eks associate-access-policy \
    --cluster-name <your-cluster-name> (e.g. netflix) \
    --principal-arn <your-arn> (e.g. arn:aws:iam::820242925270:user/akil) \
    --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
    --access-scope type=cluster \
    --region <your-region> (e.g. us-east-1)

    Command 2:

    aws eks list-associated-access-policies \
    --cluster-name <your-cluster-name> (e.g. netflix) \
    --principal-arn <your-arn> (e.g. arn:aws:iam::820242925270:user/akil) \
    --region <your-region> (e.g. us-east-1)

    Command 3:

    aws eks update-kubeconfig --region <your-region> (e.g. us-east-1) --name <your-cluster-name> (e.g. netflix) --profile <your-profile-name> (e.g. akil)
    kubectl get ns

    Note:
    Your ARN can be found in AWS console dashboard > IAM > Users > Your-User-Name
    
    Security Note
    Do not share your Secret Access Key with anyone.
    
    Rotate and manage credentials securely, following AWS best practices.
    ```

    make sure to check these requirements for better experience (optional):

    ```
    1. Check VPC and Subnet
    Go to: AWS Console > EC2 > Instances
    
    Select your instance. In the "Description" tab, find VPC ID and Subnet ID. Note these values.
    
    Go to: AWS Console > EKS > Clusters > Select your cluster ("netflix")
    
    Look for: "Networking" section (may be under cluster details). Find VPC ID, Subnet IDs—make sure your EC2 and control plane ENIs are in the same VPC.
    
    2. Review Route Table
    Go to: AWS Console > VPC > Subnets
    
    Select your EC2's subnet. In its details pane, find Route Table.
    
    Click: The Route Table link, and then open the Routes tab.
    
    See: At least one route:
    
    Destination: <your VPC CIDR> (e.g., 172.31.0.0/16)
    
    Target: local
    
    If public endpoint:
    
    Destination: 0.0.0.0/0
    
    Target: <your Internet Gateway ID>
    
    3. Security Groups Check
    Go to: AWS Console > EC2 > Instances > Your EC2 > "Security" tab
    
    Click the Security Group. Review Outbound rules.
    
    See:
    
    Type: HTTPS, Port range: 443, Destination: 0.0.0.0/0 or VPC CIDR
    
    Or a rule that allows all outbound traffic
    
    Go to: AWS Console > EKS > Clusters > Networking
    
    Find: "Cluster security group" or "Endpoint ENI security group." Open it.
    
    See:
    
    Inbound rule: Type: HTTPS, Port range: 443, Source: EC2 security group, subnet CIDR, or VPC CIDR
    
    4. Network ACLs Review
    Go to: AWS Console > VPC > Subnets > your EC2 subnet > "Network ACL" tab
    
    Click the Network ACL.
    
    See:
    
    Inbound/outbound rules: ALLOW for TCP 443, and Allow for ephemeral ports (1024-65535)
    
    No DENY rules that block required comms
    
    5. EKS Endpoint Access Settings
    Go to: AWS Console > EKS > Clusters > Networking
    
    Click: "Manage endpoint access" (if shown).
    
    See:
    
    Is endpoint "Public," "Private," or both?
    
    If public, you can add your EC2's public IP (or VPC CIDR) to the allowed list to test.
    
    If private, ensure your EC2's subnet is listed. Otherwise, the API won't be reachable.
    ```

5. Install the Node Exporter using Helm:

    ```bash
    helm install prometheus-node-exporter prometheus-community/prometheus-node-exporter --namespace prometheus-node-exporter
    ```

Add a Job to Scrape Metrics on nodeip:9001/metrics in prometheus.yml:

Update your Prometheus configuration (prometheus.yml) to add a new job for scraping metrics from nodeip:9001/metrics. You can do this by adding the following configuration to your prometheus.yml file:


```
  - job_name: 'netflix'
    metrics_path: '/metrics'
    static_configs:
      - targets: ['node1Ip:9100']
```

6. Export ArgoCD
   execute this command in your EC2 instance:
   ```bash
   export ARGOCD_SERVER=$(kubectl get svc argocd-server -n argocd -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname')
   ```

Replace 'your-job-name' with a descriptive name for your job. The static_configs section specifies the targets to scrape metrics from, and in this case, it's set to nodeip:9001.

Don't forget to reload or restart Prometheus to apply these changes to your configuration.

To deploy an application with ArgoCD, you can follow these steps, which I'll outline in Markdown format:

### Deploy Application with ArgoCD

1. **Install ArgoCD:**

   You can install ArgoCD on your Kubernetes cluster by following the instructions provided in the [EKS Workshop](https://eksworkshop.com/docs/automation/gitops/argocd/access_argocd) documentation.

   Or
   
   Go to the EC2 Dashboard in the AWS Console.
    
   Select your EC2 instance, then go to the “Security” tab and review the attached security groups.
    
   Ensure there is an outbound rule that allows all traffic or at least TCP port 443 (HTTPS) to anywhere (0.0.0.0/0) or to the EKS API server IP.

   Then execute these commands in your ec2 instance terminal:

   ```bash
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   kubectl get pods -n argocd
   ```

2. **Export your ArgoCD and Sign in:**

   Execute this command to export your ArgoCD:
   
   ```bash
   kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"LoadBalancer"}}'
   until kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null | grep -E '.+'; do echo "waiting for LB..."; sleep 5; done
   export ARGOCD_SERVER="$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
   echo "$ARGOCD_SERVER"
   ```

   Execute this command to get your password:

   ```bash
   export ARGO_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
   echo "ArgoCD Admin Password: $ARGO_PWD"
   ```

   If you need to restart ArgoCD:
   ```bash
   kubectl -n argocd rollout restart deploy/argocd-server
   kubectl -n argocd rollout status deploy/argocd-server
   ```

3. **Set Your GitHub Repository as a Source:**

   After installing ArgoCD, you need to set up your GitHub repository as a source for your application deployment. This typically involves configuring the connection to your repository and defining the source for your ArgoCD application. The specific steps will depend on your setup and requirements.

4. **Create an ArgoCD Application:**
   - `name`: Set the name for your application.
   - `destination`: Define the destination where your application should be deployed.
   - `project`: Specify the project the application belongs to.
   - `source`: Set the source of your application, including the GitHub repository URL, revision, and the path to the application within the repository.
   - `syncPolicy`: Configure the sync policy, including automatic syncing, pruning, and self-healing.

5. **Access your Application**
   - To Access the app make sure port 30007 is open in your security group and then open a new tab paste your NodeIP:30007, your app should be running.

**Phase 7: Cleanup**

1. **Cleanup AWS EC2 Instances:**
    - Terminate AWS EC2 instances that are no longer needed.
