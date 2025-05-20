
## ZTE 서버 바이오스 HDD RAID 설정<br> <br>
※ 서버에 HDD 장착 후 정상 녹색 점등 확인

### 1. RAID 설정
1. 서버 On 후, ‘F2’ 혹은 'DEL' 키 입력으로 BIOS 진입<br><br>
![z1](https://github.com/QubitSecurity/howto/blob/main/baremetal/RAID_Config/ZTE/images/z1.jpg)

2. Advanded 하단 ZTE SmartROC로 시작하는 메뉴 진입<br><br>
![z2](https://github.com/QubitSecurity/howto/blob/main/baremetal/RAID_Config/ZTE/images/z2.jpg)

3. Array Configuration 진입<br><br>
![z3](https://github.com/QubitSecurity/howto/blob/main/baremetal/RAID_Config/ZTE/images/z3.jpg)

4. Create Array 진입<br><br>
![z4](https://github.com/QubitSecurity/howto/blob/main/baremetal/RAID_Config/ZTE/images/z4.jpg)

5. RAID 연결할 Disk를 Enabled 로 변경 후 Proceed to next Form<br><br>
![z5](https://github.com/QubitSecurity/howto/blob/main/baremetal/RAID_Config/ZTE/images/z5.jpg)

6. RAID 레벨 선택 후 Proceed to next Form<br><br>
![z6](https://github.com/QubitSecurity/howto/blob/main/baremetal/RAID_Config/ZTE/images/z6.jpg)

7. Submit Changes<br><br>
![z7](https://github.com/QubitSecurity/howto/blob/main/baremetal/RAID_Config/ZTE/images/z7.jpg)

8. RAID 구성 완료<br><br>
![z8](https://github.com/QubitSecurity/howto/blob/main/baremetal/RAID_Config/ZTE/images/z8.jpg)

<br><br><br><br>
### 2. Hot Spare 설정

1. Array Configuration 진입<br><br>
![z3](https://github.com/QubitSecurity/howto/blob/main/baremetal/RAID_Config/ZTE/images/z3.jpg)

2. Manage Arrays 진입<br><br>
![z9](https://github.com/QubitSecurity/howto/blob/main/baremetal/RAID_Config/ZTE/images/z9.jpg)

3. Array A 진입<br><br>
![z10](https://github.com/QubitSecurity/howto/blob/main/baremetal/RAID_Config/ZTE/images/z10.jpg)

4. 하단 Manage Spare Drives<br><br>
![z11](https://github.com/QubitSecurity/howto/blob/main/baremetal/RAID_Config/ZTE/images/z11.jpg)

5. Assign Auto Replace Spare 진입<br><br>
![z12](https://github.com/QubitSecurity/howto/blob/main/baremetal/RAID_Config/ZTE/images/z12.jpg)

6. Hot Spare 로 지정할 Disk를 Enabled 후 Assign Auto Replace Spare<br><br>
![z13](https://github.com/QubitSecurity/howto/blob/main/baremetal/RAID_Config/ZTE/images/z13.jpg)

7. Submit<br><br>
![z14](https://github.com/QubitSecurity/howto/blob/main/baremetal/RAID_Config/ZTE/images/z14.jpg)

8. Hot Spare 구성 완료<br><br>
![z15](https://github.com/QubitSecurity/howto/blob/main/baremetal/RAID_Config/ZTE/images/z15.jpg)

<br><br><br><br>
### 3. 확인 방법
1. Controller Information<br><br>
![z16](https://github.com/QubitSecurity/howto/blob/main/baremetal/RAID_Config/ZTE/images/z16.jpg)

2. 하단 Configuration Summary 부분 확인<br><br>
![z17](https://github.com/QubitSecurity/howto/blob/main/baremetal/RAID_Config/ZTE/images/z17.jpg)
