@echo off
cd %~dp0
if not exist bin\platform-tools-windows (
	echo.
	echo.请解压使用，或重新解压
	pause
	exit
)
if not exist bin\platform-tools-windows\cecho.exe (
	echo.
	echo.组件被删除，请关掉杀毒软件或Windows安全中心后重新解压
	pause
	exit
)
if not exist bin\platform-tools-windows\fastboot.exe (
	echo.
	echo.组件被删除，请关掉杀毒软件或Windows安全中心后重新解压
	pause
	exit
)
setlocal enabledelayedexpansion
set lang=English
chcp 936 |findstr Active >nul
if "!errorlevel!" NEQ "0" set lang=Chinese
if "!lang!" == "Chinese" (
	title 小米12SPro线刷脚本 [请勿选中窗口，否则卡住活该，卡住按右键或回车或放大缩小窗口恢复]
) else (
	title Fastboot flash script
)
echo.
bin\platform-tools-windows\cecho {F0}                        {0F}{\n}
bin\platform-tools-windows\cecho {F0}     Xiaomi Hyper{F9}OS     {0F}{\n}
bin\platform-tools-windows\cecho {F0}        {F2}X-{F3}MiPort        {0F}{\n}
bin\platform-tools-windows\cecho {F0}                        {0F}{\n}
if "!lang!" == "Chinese" (
	echo.
	echo.移植作者：酷安@XMiPort
	echo.作者  QQ: 2073593801
	echo.作者微信: X-MiPort
	echo.尊重原创，禁止倒卖
	echo.
	echo.-------ROM INFO-------
	echo.加密状态:Data解密
	echo.机型代号:UNICORN
	echo.机型名称:Xiaomi 12S Pro
	echo.底包版本:OS3.0.4.0.VLECNXM
	echo.移植机型:Xiaomi 18 Pro Max
	echo.移植版本:OS4.0.27.0.XEOCNXM
	echo.----------------------
	echo.
	echo.刷机注意事项：
	echo.① 首次需要清除数据
	echo.② 解密Data和不解密Data的包互刷需要清除数据
) else (
	echo.
	echo.-------ROM INFO-------
	echo.Data State:DataDecryption
	echo.Device Code:UNICORN
	echo.Device Name:Xiaomi 12S
	echo.Base ROM Version:OS3.0.4.0.VLECNXM
	echo.Port From:Xiaomi 18 Pro Max
	echo.Port Version:OS4.0.27.0.XEOCNXM
	echo.----------------------
	echo.
	echo.Notes：
	echo.1.Please flash with data format if you are the first time to flash PureSky ROM
	echo.2.The ROM switch between decrypted Data and undecrypted Data needs to format data
)


if exist images\super.img.zst (
	echo.
	if "!lang!" == "Chinese" (
		echo.正在转换...
	) else (
		echo.Decompressing super.img.zst...
	)
	bin\platform-tools-windows\zstd --rm -d images/super.img.zst -o images/super.img
	if "!errorlevel!" NEQ "0" (
		if "!lang!" == "Chinese" (
			echo.Super.img转换可能出错，请不要刷入！
			echo.如果提示"No space left on device"则是你电脑空间不足，请释放后重新解压再刷入
			echo.如果是其他提示，请联系QQ 2073593801
		) else (
			echo.An error occurred while decompressing super.
			echo.If it prompts "No space left on device", it means that your computer has insufficient space. Please release it, decompress the ROM again, and then flash it.
			echo.If there are other tips, please contact me with QQNumber 2073593801.
		)
		pause
		exit
	)
)
echo.
if "!lang!" == "Chinese" (
	echo.线刷需要将手机进入fastboot模式，并用数据线连接电脑
) else (
	echo.Please put your device into fastboot mode and connect it to the computer with usb cable.
	echo.Please put your device into fastboot mode and connect it to the computer with usb cable.
)
echo.
if "!lang!" == "Chinese" (
	echo.刷机过程中请不要乱动乱点，请注意看窗口标题
	echo.
	echo.如果卡住请下载驱动 "https://lsdy.top/azqd"
	echo.
)
echo.检查设备BL解锁状态
echo.
bin\platform-tools-windows\fastboot getvar unlocked 2>&1 |findstr yes ||echo.不解锁刷个毛线
echo.
if "!lang!" == "Chinese" (
	set /p wipeData="是否需要清除数据（y/n）"
) else (
	set /p wipeData="Flash with data format?[y/n]"
)
echo.

echo.请将手机进入fastboot模式，并用数据线连接电脑，如果没反应请装驱动，如已进fastboot且已装驱动仍没反应请换数据线或usb接口
echo.
echo.
for /f "tokens=2 delims=:" %%i in ('bin\platform-tools-windows\fastboot getvar cpuid 2^>^&1 ^|findstr cpuid') do set cpuid=%%i
for /f %%i in ('echo.!cpuid! ^|findstr 0x0000') do set isHex=%%i
if "!isHex!" == "" (
	for /f %%i in ('bin\platform-tools-windows\printf %%d !cpuid!') do set cpuid=%%i
)
if "!lang!" == "Chinese" (
	echo.你的主板ID为： !cpuid! ，请复制发给ROM作者（群主）
	echo.你的主板ID为： !cpuid! ，请复制发给ROM作者（群主）
	echo.
	echo.如果未加群，请加我QQ：2073593801
	echo.如果未加群，请加我QQ：2073593801
) else (
	echo.Your Device's CPUID: !cpuid!
)
echo.
echo.
bin\platform-tools-windows\fastboot getvar product 2>&1 |findstr /i UNICORN
if "!errorlevel!" neq "0" (
	for /f %%i in ('bin\platform-tools-windows\fastboot getvar product 2^>^&1 ^|findstr product ^|bin\platform-tools-windows\cut -d ":" -f 2') do set readproduct=%%i
	color 0c
	if "!lang!" == "Chinese" (
		echo.机型代号检验不通过，你的机型代号为 !readproduct!，而ROM指定的机型代号为 UNICORN
		echo.
		set /p ctnflash="是否继续刷入？[y/n]"
	) else (
		echo.The product test failed. Your product is !readproduct!, but the product specified by ROM is UNICORN
		echo.
		set /p ctnflash="Do you want to continue flashing?[y/n]"
	)
	if /i "!ctnflash!" NEQ "y" exit 
	color 0f
)

set errorsum=0

REM if "!lang!" == "Chinese" (
	REM set /p refresh="是否需要全局高刷？（y/n）"
REM ) else (
	REM set /p refresh="DO you want to lock highest refresh rate?[y/n]"
REM )

REM if /i "!refresh!" == "y" (
	REM bin\platform-tools-windows\fastboot flash dtbo_ab images/dtbo_mod.img ||call :ERROR_FLASH dtbo_ab
REM ) else (
	REM bin\platform-tools-windows\fastboot flash dtbo_ab images/dtbo.img ||call :ERROR_FLASH dtbo_ab
REM )

if exist images\recovery_twrp.img (
	if "!lang!" == "Chinese" (
		set /p twrpOrNot="是否需要TWRP？（y/n）"
	) else (
		set /p twrpOrNot="Flash TWRP custom recovery?[y/n]"
	)
)

:ROOT_SELECTER
if "!lang!" == "Chinese" (
	echo.
	echo.-------ROOT 选择器-------
	echo.
	echo.  ^<1^> 无需ROOT
	echo.  ^<2^> Magisk
	echo.  ^<3^> APatch
	echo.  ^<4^> FolkPatch
	echo.  ^<5^> KernelSU
	echo.  ^<6^> SukiSU-Ultra
	echo.  ^<7^> KernelSU-Next
	echo.  ^<8^> Kitesune Mask
	echo.
	echo.------------------------
	echo.
	set /p rootType="请选择你的ROOT方式："
) else (
	echo.
	echo.-------ROOT Selecter-------
	echo.
	echo.  ^<1^> NoROOT
	echo.  ^<2^> Magisk
	echo.  ^<3^> APatch
	echo.  ^<4^> FolkPatch
	echo.  ^<5^> KernelSU
	echo.  ^<6^> SukiSU-Ultra
	echo.  ^<7^> KernelSU-Next
	echo.  ^<8^> Kitesune Mask
	echo.
	echo.---------------------------
	echo.
	set /p rootType="Select a root type:"
)
echo.
if "!rootType!" EQU "1" (
	echo.NoROOT
	echo.
	bin\platform-tools-windows\fastboot flash boot_ab images/boot_official.img
	echo.
	goto NEXT_FLASHER
)
if "!rootType!" EQU "2" (
	echo.Magisk
	echo.
	bin\platform-tools-windows\fastboot flash boot_ab images/boot_magisk.img
	goto NEXT_FLASHER
)
if "!rootType!" EQU "3" (
	echo.APatch
	echo.
	bin\platform-tools-windows\fastboot flash boot_ab images/boot_apatch.img
	echo.
	goto NEXT_FLASHER
)
if "!rootType!" EQU "4" (
	echo.FolkPatch
	echo.
	bin\platform-tools-windows\fastboot flash boot_ab images/boot_folkpatch.img
	echo.
	goto NEXT_FLASHER
)
if "!rootType!" EQU "5" (
	echo.KernelSU
	echo.
	bin\platform-tools-windows\fastboot flash boot_ab images/boot_ksu.img
	echo.
	goto NEXT_FLASHER
)
if "!rootType!" EQU "6" (
	echo.SukiSU-Ultra
	echo.
	bin\platform-tools-windows\fastboot flash boot_ab images/boot_sukisu.img
	echo.
	goto NEXT_FLASHER
)
if "!rootType!" EQU "7" (
	echo.KernelSU-Next
	echo.
	bin\platform-tools-windows\fastboot flash boot_ab images/boot_ksu-next.img
	echo.
	goto NEXT_FLASHER
)
if "!rootType!" EQU "8" (
	echo.Kitesune Mask
	echo.
	bin\platform-tools-windows\fastboot flash boot_ab images/boot_kitsune-mask.img
	echo.
	goto NEXT_FLASHER
)
goto ROOT_SELECTER

:NEXT_FLASHER

if exist images\recovery_twrp.img (
	if /i "!twrpOrNot!" == "y" (
		bin\platform-tools-windows\fastboot flash recovery_ab images/recovery_twrp.img ||call :ERROR_FLASH recovery_ab
	)
)


rem
bin\platform-tools-windows\fastboot erase frp
bin\platform-tools-windows\fastboot getvar all 2>&1 |findstr "partition-type:cust" && bin\platform-tools-windows\fastboot erase cust
bin\platform-tools-windows\fastboot flash xbl_ramdump_ab images/xbl_ramdump.img ||call :ERROR_FLASH xbl_ramdump_ab
bin\platform-tools-windows\fastboot flash xbl_config_ab images/xbl_config.img ||call :ERROR_FLASH xbl_config_ab
bin\platform-tools-windows\fastboot flash xbl_ab images/xbl.img ||call :ERROR_FLASH xbl_ab
bin\platform-tools-windows\fastboot flash vm-bootsys_ab images/vm-bootsys.img ||call :ERROR_FLASH vm-bootsys_ab
bin\platform-tools-windows\fastboot flash vendor_boot_ab images/vendor_boot.img ||call :ERROR_FLASH vendor_boot_ab
bin\platform-tools-windows\fastboot --disable-verity --disable-verification flash vbmeta_system_ab images/vbmeta_system.img ||call :ERROR_FLASH vbmeta_system_ab
bin\platform-tools-windows\fastboot --disable-verity --disable-verification flash vbmeta_ab images/vbmeta.img ||call :ERROR_FLASH vbmeta_ab
bin\platform-tools-windows\fastboot flash uefisecapp_ab images/uefisecapp.img ||call :ERROR_FLASH uefisecapp_ab
bin\platform-tools-windows\fastboot flash uefi_ab images/uefi.img ||call :ERROR_FLASH uefi_ab
bin\platform-tools-windows\fastboot flash tz_ab images/tz.img ||call :ERROR_FLASH tz_ab
bin\platform-tools-windows\fastboot flash shrm_ab images/shrm.img ||call :ERROR_FLASH shrm_ab
bin\platform-tools-windows\fastboot flash qupfw_ab images/qupfw.img ||call :ERROR_FLASH qupfw_ab
bin\platform-tools-windows\fastboot flash modem_ab images/modem.img ||call :ERROR_FLASH modem_ab
bin\platform-tools-windows\fastboot flash keymaster_ab images/keymaster.img ||call :ERROR_FLASH keymaster_ab
bin\platform-tools-windows\fastboot flash imagefv_ab images/imagefv.img ||call :ERROR_FLASH imagefv_ab
bin\platform-tools-windows\fastboot flash hyp_ab images/hyp.img ||call :ERROR_FLASH hyp_ab
bin\platform-tools-windows\fastboot flash featenabler_ab images/featenabler.img ||call :ERROR_FLASH featenabler_ab
bin\platform-tools-windows\fastboot flash dtbo_ab images/dtbo.img ||call :ERROR_FLASH dtbo_ab
bin\platform-tools-windows\fastboot flash dsp_ab images/dsp.img ||call :ERROR_FLASH dsp_ab
bin\platform-tools-windows\fastboot flash devcfg_ab images/devcfg.img ||call :ERROR_FLASH devcfg_ab
bin\platform-tools-windows\fastboot flash cpucp_ab images/cpucp.img ||call :ERROR_FLASH cpucp_ab
bin\platform-tools-windows\fastboot flash bluetooth_ab images/bluetooth.img ||call :ERROR_FLASH bluetooth_ab
bin\platform-tools-windows\fastboot flash aop_ab images/aop.img ||call :ERROR_FLASH aop_ab
bin\platform-tools-windows\fastboot flash aop_config_ab images/aop_config.img ||call :ERROR_FLASH aop_config_ab
bin\platform-tools-windows\fastboot flash abl_ab images/abl.img ||call :ERROR_FLASH abl_ab


if exist images\cust.img bin\platform-tools-windows\fastboot flash cust images/cust.img ||call :ERROR_FLASH cust
echo.
echo.
if "!lang!" == "Chinese" (
	echo.如果显示 invalid sparse file format at header magic 为正常情况，不是报错
	echo.如果显示 invalid sparse file format at header magic 为正常情况，不是报错
) else (
	echo.If invalid sparse file format at header magic is displayed, it is normal and not an error.
	echo.If invalid sparse file format at header magic is displayed, it is normal and not an error.
)
echo.
if "!lang!" == "Chinese" (
	echo.请耐心等待，卡在这里多久取决于电脑性能，也可以看下标题
	echo.请耐心等待，卡在这里多久取决于电脑性能，也可以看下标题
) else (
	echo.Please wait patiently. How long it takes to be stuck here depends on the performance of your computer.
	echo.Please wait patiently. How long it takes to be stuck here depends on the performance of your computer.
)
echo.
echo.
if exist images\super.img bin\platform-tools-windows\fastboot flash super images/super.img ||call :ERROR_FLASH super
echo.
echo.
if "!lang!" == "Chinese" (
	echo.刷完super可能会卡一段时间，请耐心等待，请勿自行重启，否则可能不开机需要重刷
	echo.刷完super可能会卡一段时间，请耐心等待，请勿自行重启，否则可能不开机需要重刷
) else (
	echo.After flashing super, it may be stuck for a while. Please wait patiently and do not restart by yourself, otherwise it may not boot and need to be flashed again.
	echo.After flashing super, it may be stuck for a while. Please wait patiently and do not restart by yourself, otherwise it may not boot and need to be flashed again.
)
echo.
if "!lang!" == "Chinese" (
	echo.如果长时间没有反应，请尝试手动开机或者重刷一遍
	echo.如果长时间没有反应，请尝试手动开机或者重刷一遍
) else (
	echo.If there is no response for a long time, please try to turn it on manually or flash again.
	echo.If there is no response for a long time, please try to turn it on manually or flash again.
)
echo.
echo.


if /i "!wipeData!" == "y" (
	if "!lang!" == "Chinese" (
		echo.正在清除数据
		bin\platform-tools-windows\fastboot erase userdata ||call :ERROR_OPRATE 清除数据失败
		bin\platform-tools-windows\fastboot erase metadata ||call :ERROR_OPRATE 清除数据失败
	) else (
		echo.Formatting data
		bin\platform-tools-windows\fastboot erase userdata ||call :ERROR_OPRATE Failed to format data
		bin\platform-tools-windows\fastboot erase metadata ||call :ERROR_OPRATE Failed to format data
	)
	echo.
	echo.
)
if "!lang!" == "Chinese" (
	bin\platform-tools-windows\fastboot set_active a ||call :ERROR_OPRATE 切换槽位指令执行失败
) else (
	bin\platform-tools-windows\fastboot set_active a ||call :ERROR_OPRATE Failed to switch slot into a
)
echo.Rebooting your device
if "!lang!" == "Chinese" (
	bin\platform-tools-windows\fastboot reboot ||call :ERROR_OPRATE 重启指令执行失败
) else (
	bin\platform-tools-windows\fastboot reboot ||call :ERROR_OPRATE Failed to reboot
)
echo.
echo.
if "!errorsum!" == "0" (
	color 0a
	if "!lang!" == "Chinese" (
		echo.刷机脚本执行完毕，刷机过程无异常
		echo.刷机脚本执行完毕，刷机过程无异常
	) else (
		echo.Flash done, no error
		echo.Flash done, no error
	)
) else (
	color 0c
	if "!lang!" == "Chinese" (
		echo.刷机脚本执行完毕，刷机出现异常，异常次数：!errorsum!
		echo.刷机脚本执行完毕，刷机出现异常，异常次数：!errorsum!
		echo.刷机脚本执行完毕，刷机出现异常，异常次数：!errorsum!
		echo.
		echo.请自行尝试重新进Fastboot刷/换接口重刷/换数据线重刷/换电脑重刷
		echo.请自行尝试重新进Fastboot刷/换接口重刷/换数据线重刷/换电脑重刷
		echo.请自行尝试重新进Fastboot刷/换接口重刷/换数据线重刷/换电脑重刷
		echo.
	) else (
		echo.After the flashing script is executed, !errorsum! exceptions occurs during flashing.
		echo.After the flashing script is executed, !errorsum! exceptions occurs during flashing.
		echo.After the flashing script is executed, !errorsum! exceptions occurs during flashing.
	)
)
echo.
echo.
if "!lang!" == "Chinese" (
	echo.如果不开机请尝试刷回上个版本
	echo.如果不开机请尝试刷回上个版本
	echo.如果不开机请尝试刷回上个版本
	echo.
	echo.如果选了ROOT，请自行在ROM包的RootManager文件夹安装对应的管理器
	echo.如果选了ROOT，请自行在ROM包的RootManager文件夹安装对应的管理器
	echo.如果选了ROOT，请自行在ROM包的RootManager文件夹安装对应的管理器
	echo.
) else (
	echo.If it does not boot, please try to flash back to the previous version.
	echo.If it does not boot, please try to flash back to the previous version.
	echo.If it does not boot, please try to flash back to the previous version.
)
echo.
echo.
if "!lang!" == "Chinese" (
	echo.你的主板ID为： !cpuid! ，请复制发给ROM作者（群主）
	echo.你的主板ID为： !cpuid! ，请复制发给ROM作者（群主）
	echo.
	echo.如果未加群，请加我QQ：2073593801
	echo.如果未加群，请加我QQ：2073593801
) else (
	echo.Your Device's CPUID: !cpuid! ,please copy it and send to the romer
)
pause
exit


:ERROR_FLASH
set /a errorsum+=1
echo.
if "!lang!" == "Chinese" (
	echo.刷机错误：
) else (
	echo.Flash error:
)
echo.
if "!lang!" == "Chinese" (
	echo.    刷入 %* 分区时出现错误
) else (
	echo.	An error occurred while flash partition %*
)
echo.
exit /b

:ERROR_OPRATE
set /a errorsum+=1
color 0c
echo.
if "!lang!" == "Chinese" (
	echo.Fastboot指令执行出错：
) else (
	echo.Fastboot command error:
)
echo.
echo.    %*
echo.
exit /b