
BIOS IBMC 설정 방법

1. 바이오스 진입 후, Server Mgmt 탭으로 이동 후 BMC Network Conrfiguration 진입<br><br>
![bmc1](https://github.com/QubitSecurity/documentation/blob/main/Physical_Server/IBMC_Config/images/bmc1.png)
2. Sharelink Network ‘Disabled’ 설정<br><br>
![bmc2](https://github.com/QubitSecurity/documentation/blob/main/Physical_Server/IBMC_Config/images/bmc2.png)

3. BMC IPv4 Network Configuration 진입<br><br>
![bmc3](https://github.com/QubitSecurity/documentation/blob/main/Physical_Server/IBMC_Config/images/bmc3.png)

4. BMC Sharelink 부분은 Disabled 하고, BMC Dedicated Management Channel 설정을 Static 으로 설정 후 Station IP Address, Subnet mask, Router IP Address 를 설정하고 저장하고  종료<br><br>
![bmc4](https://github.com/QubitSecurity/documentation/blob/main/Physical_Server/IBMC_Config/images/bmc4.png)

5. 서버 부팅 후, IBMC Network 설정 확인<br><br>
![bmc5](https://github.com/QubitSecurity/documentation/blob/main/Physical_Server/IBMC_Config/images/bmc5.png)
