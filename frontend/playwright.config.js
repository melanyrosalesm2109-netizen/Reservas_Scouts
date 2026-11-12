import process from "node:process";
import { existsSync } from "node:fs";
import path from "node:path";
import { defineConfig } from "@playwright/test";

const baseURL = process.env.E2E_BASE_URL || "http://localhost:5173";
const chromePaths = [process.env.LOCALAPPDATA, process.env.PROGRAMFILES]
  .filter(Boolean)
  .map((root) => path.join(root, "Google", "Chrome", "Application", "chrome.exe"));
const edgePath = path.join(process.env["ProgramFiles(x86)"] || "", "Microsoft", "Edge", "Application", "msedge.exe");
const browserChannel = process.env.PLAYWRIGHT_CHANNEL || (
  process.platform === "win32" && !chromePaths.some(existsSync) && existsSync(edgePath)
    ? "msedge"
    : "chrome"
);

export default defineConfig({
  testDir: "./e2e",
  fullyParallel: false,
  forbidOnly: Boolean(process.env.CI),
  retries: 0,
  workers: 1,
  reporter: "list",
  use: {
    baseURL,
    channel: browserChannel,
    headless: true,
    trace: "retain-on-failure"
  },
  webServer: {
    command: "npm run dev -- --host localhost --port 5173",
    url: baseURL,
    reuseExistingServer: !process.env.CI,
    timeout: 30_000
  }
});
