# Spring Boot CI/CD Pipeline with Jenkins, SonarQube, Docker, and ArgoCD

A complete CI/CD pipeline demonstrating automated build, test, code analysis, containerization, and deployment to Kubernetes using GitOps principles.

## 📋 Table of Contents
- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Infrastructure Setup](#infrastructure-setup)
- [Pipeline Configuration](#pipeline-configuration)
- [Running the Application](#running-the-application)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Project Overview

This project implements a **complete CI/CD pipeline** for a Spring Boot application with:
- ✅ Automated builds with Maven
- ✅ Code quality analysis with SonarQube
- ✅ Docker containerization
- ✅ GitOps deployment with ArgoCD
- ✅ Kubernetes orchestration

### Tech Stack
- **Language:** Java 11
- **Framework:** Spring Boot 2.5.14
- **Build Tool:** Maven 3.8
- **CI/CD:** Jenkins 2.x
- **Code Quality:** SonarQube 9.9 LTS
- **Container:** Docker
- **Orchestration:** Kubernetes (Minikube)
- **GitOps:** ArgoCD

---

## 🏗️ Architecture

```
Developer → GitHub → Jenkins Pipeline → Docker Hub → ArgoCD → Kubernetes → Users
                         ↓
                    SonarQube
```

**Pipeline Stages:**
1. **Checkout** - Clone code from GitHub
2. **Build & Test** - Maven build and unit tests
3. **Code Analysis** - SonarQube quality check
4. **Docker Build** - Create and push image
5. **Update Deployment** - Update Kubernetes manifest
6. **Auto Deploy** - ArgoCD syncs to cluster

---

## 📦 Prerequisites

- Ubuntu 20.04+ or similar Linux distribution
- 4GB RAM minimum (8GB recommended)
- 20GB free disk space
- Sudo privileges

---

## 🛠️ Infrastructure Setup

### 1️⃣ Install Jenkins

```bash
# Install Java 11
sudo apt update
sudo apt install -y openjdk-11-jdk

# Add Jenkins repository
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Install Jenkins
sudo apt update
sudo apt install -y jenkins

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# Access Jenkins at: http://<your-ip>:8080
```

**Post-Installation:**
- Install suggested plugins
- Create admin user
- Install additional plugins:
  - Docker Pipeline
  - SonarQube Scanner (optional)
  - Git

### 2️⃣ Install Docker

```bash
# Install Docker
sudo apt update
sudo apt install -y docker.io

# Add Jenkins user to docker group
sudo usermod -aG docker jenkins
sudo usermod -aG docker $USER

# Restart Jenkins
sudo systemctl restart jenkins

# Verify
docker --version
```

### 3️⃣ Setup SonarQube (Docker)

```bash
# Run SonarQube 9.9 LTS (compatible with Java 11)
docker run -d \
  --name sonarqube_nti \
  --restart=unless-stopped \
  -p 9000:9000 \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  -v sonarqube_data:/opt/sonarqube/data \
  -v sonarqube_extensions:/opt/sonarqube/extensions \
  -v sonarqube_logs:/opt/sonarqube/logs \
  sonarqube:9.9-community

# Wait for startup (1-2 minutes)
docker logs -f sonarqube_nti

# Access SonarQube at: http://<your-ip>:9000
# Default credentials: admin/admin
```

**SonarQube Configuration:**
1. Login and change password
2. Go to **My Account** → **Security** → **Generate Token**
   - Name: `jenkins`
   - Type: `Global Analysis Token`
   - Copy the token

### 4️⃣ Install Minikube

```bash
# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Start Minikube
minikube start --driver=docker --cpus=2 --memory=4096

# Verify
kubectl get nodes
```

### 5️⃣ Install ArgoCD

```bash
# Create ArgoCD namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods to be ready
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

# Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8081:443 &

# Access at: https://localhost:8081
# Username: admin
# Password: <from command above>
```

**ArgoCD Application Setup:**

Create `argocd-app.yaml`:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: spring-boot-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/3bdo7amouda/jenkins_demo
    targetRevision: main
    path: kubernetes
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

Apply it:
```bash
kubectl apply -f argocd-app.yaml
```

---

## ⚙️ Pipeline Configuration

### 1️⃣ Jenkins Credentials

Go to **Manage Jenkins** → **Credentials** → **Global** → **Add Credentials**

**Create three credentials:**

1. **SonarQube Token**
   - Kind: `Secret text`
   - Secret: `<your-sonarqube-token>`
   - ID: `sonarqube`

2. **Docker Hub**
   - Kind: `Username with password`
   - Username: `<your-dockerhub-username>`
   - Password: `<your-dockerhub-password>`
   - ID: `docker-cred`

3. **GitHub Token**
   - Kind: `Secret text`
   - Secret: `<your-github-personal-access-token>`
   - ID: `github`
   
   Generate GitHub token at: https://github.com/settings/tokens
   - Scopes: `repo` (all)

### 2️⃣ Create Jenkins Pipeline Job

1. **New Item** → Name: `lab-3` → **Pipeline** → **OK**
2. Under **Pipeline** section:
   - Definition: `Pipeline script from SCM`
   - SCM: `Git`
   - Repository URL: `https://github.com/3bdo7amouda/jenkins_demo`
   - Branch: `main`
   - Script Path: `JenkinsFile`
3. **Save**

### 3️⃣ Fix Workspace Permissions

```bash
# Fix ownership issues
sudo chown -R jenkins:jenkins /var/lib/jenkins/workspace/

# Add gitignore for target directory
cd ~/jenkins_demo
echo "target/" >> .gitignore
git add .gitignore
git commit -m "Add gitignore"
git push origin main
```

---

## 🚀 Running the Application

### Trigger Pipeline

1. Go to Jenkins → **lab-3** → **Build Now**
2. Watch the pipeline stages execute
3. Check SonarQube for code quality report
4. Verify Docker image pushed to Docker Hub
5. ArgoCD automatically deploys to Kubernetes

### Access the Application

```bash
# Method 1: Minikube service
minikube service spring-boot-app-service

# Method 2: Port forward
kubectl port-forward svc/spring-boot-app-service 8082:80

# Method 3: Direct NodePort
MINIKUBE_IP=$(minikube ip)
NODE_PORT=$(kubectl get svc spring-boot-app-service -o jsonpath='{.spec.ports[0].nodePort}')
echo "Access at: http://$MINIKUBE_IP:$NODE_PORT"
```

### Verify Deployment

```bash
# Check pods
kubectl get pods

# Check logs
kubectl logs -l app=spring-boot-app -f

# Check service
kubectl get svc spring-boot-app-service

# ArgoCD sync status
kubectl get applications -n argocd
```

---

## 🔧 Troubleshooting

### Permission Denied Errors

```bash
# Fix workspace permissions
sudo chown -R jenkins:jenkins /var/lib/jenkins/workspace/lab-3
```

### SonarQube Connection Issues

```bash
# Check SonarQube is running
docker ps | grep sonarqube

# Restart if needed
docker restart sonarqube_nti

# View logs
docker logs sonarqube_nti
```

### Pod CrashLoopBackOff

```bash
# Check pod logs
kubectl logs -l app=spring-boot-app

# Common issue: Java version mismatch
# Solution: Rebuild with correct Java 11 setup
```

### ArgoCD Not Syncing

```bash
# Manual sync
kubectl patch application spring-boot-app -n argocd --type merge -p '{"operation": {"sync": {}}}'

# Check ArgoCD logs
kubectl logs -n argocd deployment/argocd-server
```

### Docker Build Fails

```bash
# Ensure Docker is accessible
docker ps

# Add jenkins to docker group if needed
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

---

## 📊 Project Structure

```
jenkins_demo/
├── src/main/java/              # Java source code
├── src/main/resources/         # Application properties, static files
├── kubernetes/                 # Kubernetes manifests
│   ├── deployment.yml         # Pod deployment config
│   └── service.yml            # Service exposure config
├── pom.xml                    # Maven dependencies
├── Dockerfile                 # Container image definition
└── JenkinsFile                # CI/CD pipeline definition
```

---

## 🎓 Learning Resources

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [SonarQube Docs](https://docs.sonarqube.org/)
- [Docker Guide](https://docs.docker.com/)
- [Kubernetes Basics](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
- [ArgoCD Getting Started](https://argo-cd.readthedocs.io/en/stable/getting_started/)

---

## 📝 Notes

- **Java Version:** Project uses Java 11
- **SonarQube:** Use version 9.9 LTS for Java 11 compatibility
- **Ports Used:** 8080 (Jenkins), 9000 (SonarQube), 8081 (ArgoCD)
- **Default Credentials:** Change all default passwords in production

---

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

---

## 📄 License

This project is for educational purposes.

---

**Total Setup Time:** ~30-45 minutes  
**Pipeline Duration:** ~2-3 minutes per build

🚀 **Happy DevOps!**


