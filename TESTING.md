# Testing the app against your local Frappe site

Your bench is running inside WSL2:

```
http://127.0.0.1:8000      (from inside WSL)
http://172.28.16.92:8000   (WSL2 eth0 — only reachable from WSL)
```

The challenge: WSL2 runs in a separate virtual network. The right
`API_BASE_URL` depends on **where the Flutter app runs**.

---

## Option 1 — Android emulator on Windows (easiest)

Windows auto-forwards `localhost` to WSL2, and the emulator reaches the
Windows host through `10.0.2.2`.

1. **`.env`**
   ```
   API_BASE_URL=http://10.0.2.2:8000
   ```

2. **Allow HTTP traffic on Android 9+** (otherwise the emulator silently
   blocks cleartext requests).

   After running `flutter create . --platforms=android,ios`:

   `android/app/src/main/res/xml/network_security_config.xml` — create it:
   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <network-security-config>
     <base-config cleartextTrafficPermitted="true">
       <trust-anchors>
         <certificates src="system" />
       </trust-anchors>
     </base-config>
   </network-security-config>
   ```

   In `android/app/src/main/AndroidManifest.xml`, inside `<application …>`:
   ```xml
   android:networkSecurityConfig="@xml/network_security_config"
   android:usesCleartextTraffic="true"
   ```

3. **Smoke test the URL from Windows first** (PowerShell):
   ```powershell
   curl http://localhost:8000/api/method/ping
   ```
   You should get `{"message":"pong"}`. If not, your bench is unreachable
   from Windows — check `bench start` is alive.

4. **Run the app**
   ```bash
   flutter pub get
   flutter run        # picks the running emulator
   ```

---

## Option 2 — Physical Android phone over Wi-Fi

WSL2 ports are NOT exposed to your LAN automatically. You need a one-time
port forward on the Windows host.

1. **Find your Windows LAN IP** (PowerShell):
   ```powershell
   ipconfig | findstr IPv4
   ```
   Look for the Wi-Fi / Ethernet adapter address, e.g. `192.168.1.42`.

2. **Add a port proxy on Windows** (admin PowerShell):
   ```powershell
   netsh interface portproxy add v4tov4 `
     listenaddress=0.0.0.0 listenport=8000 `
     connectaddress=172.28.16.92 connectport=8000
   ```

3. **Allow port 8000 through Windows Defender** (admin PowerShell):
   ```powershell
   New-NetFirewallRule -DisplayName "Frappe 8000" `
     -Direction Inbound -LocalPort 8000 -Protocol TCP -Action Allow
   ```

4. **Update `.env`**
   ```
   API_BASE_URL=http://192.168.1.42:8000
   ```

5. **Phone and laptop must be on the same Wi-Fi.** Test from a phone
   browser by visiting `http://192.168.1.42:8000/login` — you should see
   the Frappe login page.

6. Apply the same Android cleartext config from Option 1.

7. Plug phone in, enable USB debugging, then `flutter run -d <device-id>`.

> ⚠️ The WSL2 IP (`172.28.16.92`) **changes every reboot**. Re-run the
> `netsh portproxy` command if your bench stops responding from the phone.

---

## Option 3 — iOS simulator (Mac only)

`localhost` works directly because the simulator shares the host network.

```
API_BASE_URL=http://127.0.0.1:8000
```

You don't need cleartext config — iOS allows cleartext for `localhost`
in dev builds.

---

## Option 4 — Flutter Web (Chrome) in dev

Useful for fast iteration without a device.

```
API_BASE_URL=http://localhost:8000
```

Then:
```bash
flutter run -d chrome --web-port 5173
```

Frappe must allow CORS for `http://localhost:5173`. Set in
`/home/maharajan/Dont-quit/sites/<site>/site_config.json`:
```json
{
  "allow_cors": "http://localhost:5173"
}
```

---

## Verifying the API directly

Once `API_BASE_URL` resolves, try this from the same network as your
device. If the cookie works in the browser, the app will work too.

```bash
# 1. Login
curl -c cookies.txt -X POST \
  -d 'usr=Administrator&pwd=admin' \
  http://10.0.2.2:8000/api/method/login

# 2. Hit our custom endpoint
curl -b cookies.txt http://10.0.2.2:8000/api/method/bb_acadamy_admin.api.mobile.me
```

Expected: a JSON `message` with your username, full name, roles, and
employee fields.

---

## Common failures

| Symptom                                   | Cause / fix                                                                              |
|-------------------------------------------|------------------------------------------------------------------------------------------|
| `Connection refused`                      | Bench not running, or wrong URL for that target.                                         |
| `Cleartext HTTP not permitted`            | Add the Android `network_security_config.xml` from Option 1.                             |
| `CSRFTokenError`                          | Already handled by `AuthInterceptor` (sends `X-Frappe-CSRF-Token: token`).               |
| Login works but `mobile.me` 404s          | `bench restart` after adding `bb_acadamy_admin/api/mobile.py`, or migrate not applied.   |
| Login OK but `me` 403s "no employee"      | The user has no Employee record with `user_id` linking to them.                          |
| WSL IP changed after reboot               | Re-run `netsh portproxy` with new `connectaddress`.                                      |

---

## Quick reference

```
WSL2 IP            172.28.16.92          (changes on reboot)
Bench listens on   0.0.0.0:8000          (already correct)
Windows ↔ WSL      localhost auto-forward
Emulator ↔ host    10.0.2.2:<host-port>
Phone ↔ WSL        needs netsh portproxy on Windows host
```
