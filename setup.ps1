Write-Host "========================================"
Write-Host " Kubernetes Three-Tier Application Setup"
Write-Host "========================================"

# 1. Start Minikube
Write-Host "`n[1/8] Starting Minikube..."
minikube status | Out-Null

if ($LASTEXITCODE -ne 0) {
    minikube start
}

# 2. Create namespace
Write-Host "`n[2/8] Creating namespace..."

kubectl get namespace three-tier 2>$null

if ($LASTEXITCODE -ne 0) {
    kubectl create namespace three-tier
}

# 3. Create MySQL Secret
Write-Host "`n[3/8] Creating MySQL Secret..."

$rootPassword = Read-Host "Enter MySQL root password" -AsSecureString
$appPassword = Read-Host "Enter MySQL application password" -AsSecureString

$rootPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($rootPassword)
)

$appPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($appPassword)
)

kubectl create secret generic mysql-secret `
    --from-literal=MYSQL_ROOT_PASSWORD=$rootPasswordPlain `
    --from-literal=MYSQL_USER=appuser `
    --from-literal=MYSQL_PASSWORD=$appPasswordPlain `
    -n three-tier
# 4. Create MySQL initialization ConfigMap
Write-Host "`n[4/8] Creating MySQL ConfigMap..."

kubectl get configmap mysql-initdb -n three-tier 2>$null

if ($LASTEXITCODE -ne 0) {
    kubectl create configmap mysql-initdb `
        --from-file=init.sql=database\init.sql `
        -n three-tier
}

# 5. Build Docker images
Write-Host "`n[5/8] Building Docker images..."

docker build -t three-tier-backend:v1 ./backend

if ($LASTEXITCODE -ne 0) {
    Write-Host "Backend image build failed."
    exit 1
}

docker build -t three-tier-frontend:v1 ./frontend

if ($LASTEXITCODE -ne 0) {
    Write-Host "Frontend image build failed."
    exit 1
}

# 6. Load images into Minikube
Write-Host "`n[6/8] Loading images into Minikube..."

minikube image load three-tier-backend:v1
minikube image load three-tier-frontend:v1

# 7. Deploy Kubernetes resources
Write-Host "`n[7/8] Deploying Kubernetes resources..."

kubectl apply -f k8s\mysql-pvc.yaml
kubectl apply -f k8s\mysql-statefulset.yaml

kubectl apply -f k8s\backend-deployment.yaml
kubectl apply -f k8s\backend-service.yaml

kubectl apply -f k8s\frontend-deployment.yaml
kubectl apply -f k8s\frontend-service.yaml

# 8. Display status
Write-Host "`n[8/8] Checking deployment..."

Write-Host "`nPods:"
kubectl get pods -n three-tier

Write-Host "`nServices:"
kubectl get svc -n three-tier

Write-Host "`n========================================"
Write-Host " Deployment completed!"
Write-Host "========================================"

Write-Host "`nRun the following command to open the application:"
Write-Host "minikube service frontend-service -n three-tier"

Write-Host "`n========================================"
Write-Host " Application URL"
Write-Host "========================================"

minikube service frontend-service -n three-tier --url

Write-Host "`n========================================"
Write-Host " Deployment Complete!"
Write-Host "========================================"