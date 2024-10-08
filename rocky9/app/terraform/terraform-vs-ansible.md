Terraform과 Ansible은 모두 인프라 관리와 자동화에 사용되는 도구이지만, 목적과 사용 방식에서 차이가 있습니다. 주요 차이점을 아래에 정리해 보겠습니다.

### 1. **목적**
- **Terraform**: 인프라를 코드로 정의하는 도구(IaC, Infrastructure as Code)입니다. 클라우드 리소스(서버, 네트워크, 데이터베이스 등)를 프로비저닝하는 데 중점을 둡니다. Terraform은 클라우드 인프라를 선언적으로 관리하며, 다양한 클라우드 제공업체(AWS, GCP, Azure 등)를 지원합니다.
- **Ansible**: Ansible은 구성 관리(Configuration Management), 애플리케이션 배포, 서버 프로비저닝 등 다양한 작업을 자동화하는 도구입니다. 서버에 필요한 설정, 패키지 설치 등을 주로 수행하며, 엔지니어들이 서버를 상태 기반으로 구성할 수 있도록 도와줍니다.

### 2. **작동 방식**
- **Terraform**: 선언적 언어(HCL)를 사용하여 원하는 최종 상태를 정의합니다. 사용자가 정의한 인프라 상태와 현재 상태를 비교한 후 필요한 변경만 적용합니다. 변경을 미리 계획하고 적용하기 전에 미리보기(Plan) 기능을 제공하여 예상되는 결과를 확인할 수 있습니다.
- **Ansible**: 명령적 방식으로 작동하며, 사용자가 지정한 순서대로 작업을 실행합니다. 주로 YAML 형식의 플레이북을 사용하여 작업을 정의하며, SSH 프로토콜을 통해 원격 서버에 연결하여 작업을 수행합니다. 서버 구성 관리, 애플리케이션 배포에 더 적합합니다.

### 3. **상태 관리**
- **Terraform**: 인프라의 상태를 추적하기 위해 상태 파일(state file)을 유지합니다. 이를 통해 이전 상태와 현재 상태를 비교하여 변경 사항을 효율적으로 적용할 수 있습니다.
- **Ansible**: 상태를 추적하지 않습니다. 즉, Ansible은 명령을 실행할 때마다 항상 같은 작업을 수행하며, 서버의 현재 상태에 대한 정보는 자체적으로 유지하지 않습니다. 따라서 idempotent한 태스크를 작성하여 여러 번 실행해도 동일한 결과가 나오도록 해야 합니다.

### 4. **주요 사용 사례**
- **Terraform**: AWS, GCP, Azure 등 클라우드 환경에서 가상머신(VM), 네트워크, 데이터베이스와 같은 인프라를 프로비저닝하고 관리하는 데 적합합니다. 또한, Rocky Linux 9에서 KVM(커널 기반 가상 머신) 환경을 사용하는 경우에도 적합합니다. Libvirt Provider를 사용하여 KVM 기반 가상 머신을 자동으로 생성하고 관리할 수 있으며, 가상 네트워크와 스토리지 풀을 구성하는 작업도 Terraform으로 자동화할 수 있습니다.
- **Ansible**: 서버 설정, 애플리케이션 배포, 패치 관리 등 구성 관리와 관련된 작업에 적합합니다. Ansible은 에이전트가 필요 없기 때문에 서버에 에이전트를 설치하지 않고도 작업을 수행할 수 있습니다. Ansible을 사용하면 Rocky Linux 9에서 KVM 가상 머신의 운영 체제 구성과 애플리케이션 배포를 자동화할 수 있습니다.

### 5. **확장성**
- **Terraform**: 다양한 플러그인을 통해 여러 클라우드 제공업체 및 서비스와 연동할 수 있습니다. 인프라 프로비저닝에 특화된 도구로, 이를 위한 모듈과 리소스 관리에 뛰어난 확장성을 제공합니다.
- **Ansible**: 구성 관리와 자동화 작업에 광범위하게 사용될 수 있으며, 다양한 모듈을 제공하여 거의 모든 종류의 작업을 자동화할 수 있습니다. 그러나 인프라를 정의하고 프로비저닝하는 데 있어서는 Terraform보다 덜 효율적일 수 있습니다.

### 요약
- **Terraform**은 주로 인프라 프로비저닝에 적합하며 선언적 방식으로 인프라의 최종 상태를 정의합니다.
- **Ansible**은 서버 구성 관리와 애플리케이션 배포에 적합하며, 명령적 방식으로 작업을 수행합니다.

둘은 상호보완적으로 사용될 수 있으며, Terraform으로 인프라를 프로비저닝하고 Ansible로 서버 설정 및 애플리케이션 배포를 자동화하는 방식으로 결합하여 사용할 수 있습니다.
