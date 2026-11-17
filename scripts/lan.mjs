// This computer's Wi-Fi/LAN address, for phones on the same network (LAN_IP overrides the guess).
import { networkInterfaces } from "node:os";

export function lanIp() {
  if (process.env.LAN_IP) return process.env.LAN_IP;
  const virtual = /vEthernet|WSL|Hyper-V|VirtualBox|VMware|docker|Loopback|Bluetooth/i;
  const found = Object.entries(networkInterfaces()).flatMap(([name, addrs]) =>
    (addrs ?? []).filter((a) => a.family === "IPv4" && !a.internal && !virtual.test(name)).map((a) => a.address));
  const ip = found.find((a) => a.startsWith("192.168.")) ?? found.find((a) => /^(10\.|172\.(1[6-9]|2\d|3[01])\.)/.test(a));
  if (!ip) {
    console.error("No Wi-Fi/LAN address found: set LAN_IP=<this computer's address>");
    process.exit(1);
  }
  return ip;
}
