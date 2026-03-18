import { onSchedule } from "firebase-functions/scheduler";

export const feeReminderSweep = onSchedule("every day 08:00", async () => {
  return;
});
