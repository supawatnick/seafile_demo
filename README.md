# Seafile CE 14 และ SeaDoc บน Ubuntu พร้อม ONTAP NFS

Lab VM คือ `10.10.110.69` รัน Seafile ผ่าน Docker Compose และ Caddy โดยข้อมูล Seafile อยู่บน `10.10.10.203:/seafile_01` ส่วน MariaDB อยู่ที่ `/opt/seafile-mysql/db` บน local disk ค่าเริ่มต้นใช้ HTTP สำหรับ lab ภายในที่จำกัดการเข้าถึง

## รันทีละขั้น

จาก PowerShell ในโฟลเดอร์ `Seafile` คัดลอก scripts เข้า home ของ root

```powershell
scp (Get-ChildItem -File -Filter '*.sh').FullName root@10.10.110.69:/root/
ssh root@10.10.110.69
```

บน Ubuntu ให้รันทีละคำสั่ง ตรวจผลก่อนข้ามไปขั้นถัดไป

| คำสั่ง | สิ่งที่ทำ |
|---|---|
| `bash 01-install-prerequisites.sh` | ติดตั้ง Docker และ Compose จาก Ubuntu packages หากยังไม่มี Docker พร้อมเครื่องมือ NFS |
| `bash 02-mount-ontap-nfs.sh` | Mount NFSv4.1 และทดสอบสร้างและลบไฟล์ใน export |
| `bash 03-prepare-seafile.sh` | รับอีเมล admin ดาวน์โหลดไฟล์ Compose ทางการรวม SeaDoc สร้าง secrets และตรวจ Compose config |
| `bash 04-start-seafile.sh` | ตรวจว่า ONTAP export กำลัง mount อยู่ แล้วเริ่ม Seafile และ SeaDoc |
| `bash 05-verify-seafile.sh` | แสดงสถานะ mount และ containers แล้วตรวจ Seafile API กับ SeaDoc ผ่าน Caddy |

เปิด `http://10.10.110.69` เมื่อ API ตอบ `"pong"` ใช้อีเมลจากขั้น 03 และดูรหัสผ่าน admin ที่สร้างไว้จาก root session ส่วนตัวด้วย `grep '^INIT_SEAFILE_ADMIN_PASSWORD=' /opt/seafile/.env` จากนั้นลองสร้าง library และอัปโหลด/ดาวน์โหลดไฟล์ทดสอบ

ทดสอบ SeaDoc ใน library โดยสร้างเอกสาร `.sdoc` แก้ไข แล้วเปิดใหม่เพื่อตรวจว่าข้อมูลบันทึกแล้ว

## ถ้ารันขั้น 03 ด้วยไฟล์รุ่นก่อนแล้ว

เก็บ `/opt/seafile/.env` เดิมไว้เพื่อใช้ credentials และ JWT key ชุดเดิม ดาวน์โหลด Compose ของ SeaDoc เพิ่ม

```bash
cd /opt/seafile
curl -fsSLO https://manual.seafile.com/14.0/repo/docker/seadoc.yml
nano .env
```

แก้สองบรรทัดนี้ แล้วรันขั้น 04 และ 05 จากชุดล่าสุด

```dotenv
COMPOSE_FILE=seafile-server.yml,caddy.yml,seadoc.yml,nfs-override.yml
ENABLE_SEADOC=true
```

## หลัง reboot และแก้ปัญหา

- เมื่อ VM reboot ให้รันขั้น 02, 04 และ 05 อีกครั้ง NFS mount เป็นแบบชั่วคราวและตั้ง Seafile container ให้เริ่มผ่านขั้น 04 เพื่อให้ตรวจ mount ก่อน
- ถ้า ONTAP ปฏิเสธการ mount ให้ตรวจ NFSv4.1 บน SVM และ export policy สำหรับ IP ต้นทางที่แสดงโดย `ip route get 10.10.10.203`
- ถ้า NFS test หรือ container initialization ติด permission ให้ตรวจ export policy, UID/GID และ root mapping การทดสอบขั้น 02 ใช้ root ของ Ubuntu
- ดู log ด้วย `cd /opt/seafile && docker compose logs --tail=100 seafile` ตรวจว่ามีข้อมูลลับก่อนแชร์
- หยุด stack ด้วย `cd /opt/seafile && docker compose down` จากนั้นใช้ `umount /opt/seafile-data` หากต้องการถอด mount ฐานข้อมูลและข้อมูล Seafile จะยังอยู่บนดิสก์เดิม

[คู่มือ Seafile CE 14](https://manual.seafile.com/14.0/setup/setup_ce_by_docker/) · [คู่มือ SeaDoc](https://manual.seafile.com/14.0/extension/setup_seadoc/) · [คู่มือ ONTAP NFS exports](https://docs.netapp.com/us-en/ontap/nfs-config/ontap-nfs-exports-concept.html)
