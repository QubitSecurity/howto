## 0. 서버 OS
``
Ubuntu 22.04.5 LTS
``

## 1. GPU 설치
### 1.1 GPU 인식 확인
```
# lspci | grep -i -E 'vga|3d|display'
03:00.0 VGA compatible controller: ASPEED Technology, Inc. ASPEED Graphics Family (rev 41)
3b:00.0 3D controller: NVIDIA Corporation GV100GL [Tesla V100 PCIe 16GB] (rev a1)
```
### 1.2 GPU 드라어버 설치
```
# sudo apt install nvidia-driver-535-server nvidia-utils-535-server
※ ChatGPT 권장 버전 확인
```

### 1.3 설치 확인
```
# nvidia-smi
Wed Nov 12 14:27:11 2025
+---------------------------------------------------------------------------------------+
| NVIDIA-SMI 535.274.02             Driver Version: 535.274.02   CUDA Version: 12.2     |
|-----------------------------------------+----------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |         Memory-Usage | GPU-Util  Compute M. |
|                                         |                      |               MIG M. |
|=========================================+======================+======================|
|   0  Tesla V100-PCIE-16GB           Off | 00000000:3B:00.0 Off |                    0 |
| N/A   42C    P0              37W / 250W |      0MiB / 16384MiB |      1%      Default |
|                                         |                      |                  N/A |
+-----------------------------------------+----------------------+----------------------+

+---------------------------------------------------------------------------------------+
| Processes:                                                                            |
|  GPU   GI   CI        PID   Type   Process name                            GPU Memory |
|        ID   ID                                                             Usage      |
|=======================================================================================|
|  No running processes found                                                           |
+---------------------------------------------------------------------------------------+
```

## 2. 테스트
### 2.1 테스트 환경 구축
```
# sudo apt install -y python3-venv python3-pip
# python3 -m venv ~/torch-env

# python -m pip install --upgrade pip --no-cache-dir
# pip --version
# pip install --upgrade setuptools wheel

# pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
```
### 2.2 테스트 실행
```
python 가상환경 실행 (프롬프트 앞에 (torch-env) 표기)
# source ~/torch-env/bin/activate 

테스트 1 - PyTorch 정상 설치 및 GPU(CUDA) 환경 동작 확인
(torch-env) user@gpu-server:/# python -c "import torch; print(torch.__version__); print(torch.cuda.is_available()); print(torch.cuda.get_device_name(0))"
2.5.1+cu121
True
Tesla V100-PCIE-16GB

테스트 2 - PyTorch로 GPU 연산(CUDA 연산) 작동 확인
(torch-env) user@gpu-server:/# python - <<'EOF'
import torch
a = torch.rand(10000, 10000, device='cuda')
b = torch.rand(10000, 10000, device='cuda')
c = torch.mm(a, b)
print("✅ GPU 매트릭스 곱 완료, 결과:", c.sum().item())
EOF
✅ GPU 매트릭스 곱 완료, 결과: 250026295296.0

python 가상환경 종료
(torch-env) root@gpu-server:/# deactivate
```


