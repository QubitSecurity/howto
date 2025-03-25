Bonding으로 묶여 있는 인터페이스에서 MTU 설정은 다음과 같이 진행해야 합니다.

Bond 인터페이스의 MTU를 변경할 때는 반드시 **Bond 인터페이스 본체와 이를 구성하는 Slave 인터페이스의 MTU를 동일하게 설정**하는 것이 핵심입니다.

---

## ✅ 올바른 MTU 변경 방법 (Bonding 환경)

본드 인터페이스 이름이 `bond0`, 하위 인터페이스가 `eth0`, `eth1`인 경우를 예로 듭니다.

### (1) Bond 인터페이스 MTU 변경

```bash
ip link set dev bond0 mtu 1500
```

### (2) Bond에 속한 Slave 인터페이스 MTU 변경

```bash
ip link set dev eth0 mtu 1500
ip link set dev eth1 mtu 1500
```

---

## ✅ MTU가 올바르게 변경되었는지 확인하기

```bash
ip link show bond0
ip link show eth0
ip link show eth1
```

Bond 인터페이스와 모든 Slave 인터페이스의 MTU가 동일하게 표시되는지 확인합니다.

---

## ✅ 영구적으로 설정하려면? (네트워크 재시작에도 유지)

Bonding 구성 환경(`ifcfg-*`)에서 MTU 설정은 아래와 같이 설정 파일에 추가합니다.

예시 (`/etc/sysconfig/network-scripts/ifcfg-bond0`):

```bash
MTU=1500
```

예시 (`/etc/sysconfig/network-scripts/ifcfg-eth0`, `ifcfg-eth1`):

```bash
MTU=1500
```

**이렇게 모든 인터페이스에 추가해야 합니다.**

네트워크 설정 적용:

```bash
systemctl restart network
```

적용 후 다시 확인:

```bash
ip link show bond0
ip link show eth0
ip link show eth1
```

---

## ✅ Bonding 환경에서의 주의 사항

- Bond 인터페이스와 하위 Slave 인터페이스의 MTU는 반드시 일치해야 합니다.
- MTU가 다르면, 패킷 전송 에러, 성능 저하, 통신 불안정이 발생할 수 있습니다.
- MTU 값은 보통 표준값인 `1500`으로 설정하는 것이 좋으며, 특별히 Jumbo Frame을 사용하지 않는 이상 변경하지 않는 것이 권장됩니다.

---

**✔️ 권장 설정 예시**

```bash
# Bond 인터페이스 MTU 설정
ip link set dev bond0 mtu 1500

# Slave 인터페이스 MTU 설정
ip link set dev eth0 mtu 1500
ip link set dev eth1 mtu 1500
```

이렇게 설정하면 bonding으로 묶인 환경에서 안정적이고 올바른 MTU 설정이 가능합니다.
